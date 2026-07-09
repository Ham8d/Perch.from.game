#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ============ Fake Transaction Class ============
@interface FakeTransaction : SKPaymentTransaction
@property (nonatomic, strong) SKPayment *fakePayment;
@property (nonatomic, strong) NSString  *fakeIdentifier;
@property (nonatomic, strong) NSDate    *fakeDate;
@end

@implementation FakeTransaction
@synthesize fakePayment = _fakePayment;
@synthesize fakeIdentifier = _fakeIdentifier;
@synthesize fakeDate = _fakeDate;

- (SKPayment *)payment { return _fakePayment; }
- (NSString *)transactionIdentifier { return _fakeIdentifier; }
- (NSDate *)transactionDate { return _fakeDate; }
- (SKPaymentTransactionState)transactionState { return SKPaymentTransactionStatePurchased; }
- (NSArray *)downloads { return @[]; }
- (SKPaymentTransaction *)originalTransaction { return nil; }
- (NSError *)error { return nil; }
@end

// ============ Swizzling Storage ============
static IMP originalAddPayment = NULL;
static IMP originalFinishTransaction = NULL;

// ============ Swizzled: addPayment: ============
static void swizzled_addPayment(id self, SEL _cmd, SKPayment *payment) {
    @try {
        NSArray *observers = [self valueForKey:@"observers"];
        if (!observers || observers.count == 0) {
            ((void(*)(id, SEL, SKPayment *))originalAddPayment)(self, _cmd, payment);
            return;
        }

        FakeTransaction *tx = [[FakeTransaction alloc] init];
        tx.fakePayment    = payment;
        tx.fakeIdentifier = [[NSUUID UUID] UUIDString];
        tx.fakeDate       = [NSDate date];

        for (id obs in observers) {
            if ([obs respondsToSelector:@selector(paymentQueue:updatedTransactions:)]) {
                [obs paymentQueue:self updatedTransactions:@[tx]];
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[FreeIAP] Exception in addPayment: %@", e);
        ((void(*)(id, SEL, SKPayment *))originalAddPayment)(self, _cmd, payment);
    }
}

// ============ Swizzled: finishTransaction: ============
static void swizzled_finishTransaction(id self, SEL _cmd, SKPaymentTransaction *transaction) {
    if ([transaction isKindOfClass:[FakeTransaction class]]) return;
    ((void(*)(id, SEL, SKPaymentTransaction *))originalFinishTransaction)(self, _cmd, transaction);
}

// ============ Entry Point (auto-runs on load) ============
__attribute__((constructor))
static void initializeFreeIAP(void) {
    @autoreleasepool {
        Class SKQueueClass = objc_getClass("SKPaymentQueue");
        if (!SKQueueClass) {
            NSLog(@"[FreeIAP] ✗ SKPaymentQueue not found");
            return;
        }

        Method addMethod = class_getInstanceMethod(SKQueueClass, @selector(addPayment:));
        if (addMethod) {
            originalAddPayment = method_getImplementation(addMethod);
            method_setImplementation(addMethod, (IMP)swizzled_addPayment);
        }

        Method finMethod = class_getInstanceMethod(SKQueueClass, @selector(finishTransaction:));
        if (finMethod) {
            originalFinishTransaction = method_getImplementation(finMethod);
            method_setImplementation(finMethod, (IMP)swizzled_finishTransaction);
        }

        NSLog(@"[FreeIAP] ✓ Loaded successfully");
    }
}
