#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

// ====== تزييف المعاملة (Transaction) ======
@interface FakeTransaction : SKPaymentTransaction
@property (nonatomic, strong) SKPayment *fakePayment;
@property (nonatomic, strong) NSString *fakeIdentifier;
@property (nonatomic, strong) NSDate *fakeDate;
@end

@implementation FakeTransaction
- (SKPayment *)payment { return self.fakePayment; }
- (NSString *)transactionIdentifier { return self.fakeIdentifier; }
- (NSDate *)transactionDate { return self.fakeDate; }
- (SKPaymentTransactionState)transactionState { return SKPaymentTransactionStatePurchased; }
- (NSArray<SKPaymentTransaction *> *)downloads { return @[]; }
- (SKPaymentTransaction *)originalTransaction { return nil; }
- (NSError *)error { return nil; }
@end

// ====== هوك SKPaymentQueue ======
%hook SKPaymentQueue

- (void)addPayment:(SKPayment *)payment {
    NSArray *observers = [self valueForKey:@"observers"];
    if (!observers.count) { %orig; return; }

    FakeTransaction *tx = [[FakeTransaction alloc] init];
    tx.fakePayment    = payment;
    tx.fakeIdentifier = [[NSUUID UUID] UUIDString];
    tx.fakeDate       = [NSDate date];

    for (id<SKPaymentTransactionObserver> obs in observers) {
        if ([obs respondsToSelector:@selector(paymentQueue:updatedTransactions:)]) {
            [obs paymentQueue:self updatedTransactions:@[tx]];
        }
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    if ([transaction isKindOfClass:[FakeTransaction class]]) return;
    %orig;
}

- (void)restoreCompletedTransactions {
    NSArray *observers = [self valueForKey:@"observers"];
    for (id<SKPaymentTransactionObserver> obs in observers) {
        if ([obs respondsToSelector:@selector(paymentQueueRestoreCompletedTransactionsFinished:)]) {
            [obs paymentQueueRestoreCompletedTransactionsFinished:self];
        }
    }
}

%end

// ====== هوك التحقق من المنتج (اختياري لكن مفيد) ======
%hook SKProductsRequest
- (void)start {
    %orig;
}
%end
