#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

// ====== كلاس المعاملة المزيفة ======
@interface FakeTransaction : SKPaymentTransaction
@end

@implementation FakeTransaction {
    SKPayment *_fakePayment;
    NSString  *_fakeIdentifier;
    NSDate    *_fakeDate;
}

- (instancetype)initWithPayment:(SKPayment *)payment {
    self = [super init];
    if (self) {
        _fakePayment    = payment;
        _fakeIdentifier = [[NSUUID UUID] UUIDString];
        _fakeDate       = [NSDate date];
    }
    return self;
}

- (SKPayment *)payment { return _fakePayment; }
- (NSString *)transactionIdentifier { return _fakeIdentifier; }
- (NSDate *)transactionDate { return _fakeDate; }
- (SKPaymentTransactionState)transactionState { return SKPaymentTransactionStatePurchased; }
- (NSArray *)downloads { return @[]; }
- (SKPaymentTransaction *)originalTransaction { return nil; }
- (NSError *)error { return nil; }

@end

// ====== هوك SKPaymentQueue ======
%hook SKPaymentQueue

- (void)addPayment:(SKPayment *)payment {
    NSArray *observers = [self valueForKey:@"observers"];
    if (observers == nil || observers.count == 0) {
        %orig;
        return;
    }

    FakeTransaction *tx = [[FakeTransaction alloc] initWithPayment:payment];
    NSArray *txArray = @[tx];

    for (id obs in observers) {
        if ([obs respondsToSelector:@selector(paymentQueue:updatedTransactions:)]) {
            [obs paymentQueue:self updatedTransactions:txArray];
        }
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    if ([transaction isKindOfClass:[FakeTransaction class]]) {
        return;
    }
    %orig;
}

- (void)restoreCompletedTransactions {
    NSArray *observers = [self valueForKey:@"observers"];
    for (id obs in observers) {
        if ([obs respondsToSelector:@selector(paymentQueueRestoreCompletedTransactionsFinished:)]) {
            [obs paymentQueueRestoreCompletedTransactionsFinished:self];
        }
    }
}

%end
