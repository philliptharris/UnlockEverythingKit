# UnlockEverythingKit
Easily add an In-App Purchase to "Unlock Everything" to your app!

###Setup
```objc
#import "UnlockEverythingKit.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[UnlockEverythingKit shared]];
    
    return YES;
}
```

### Purchase
```objc
[[UnlockEverythingKit shared] requestPayment];
```

### Already Purchased?
```objc
[[UnlockEverythingKit shared] restorePurchase];
```
