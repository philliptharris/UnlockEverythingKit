//
//  UnlockEverythingKit.m
//  UnlockEverythingKit
//
//  Created by Phillip Harris on 5/8/15.
//  Copyright (c) 2015 Phillip Harris. All rights reserved.
//

#import "UnlockEverythingKit.h"

NSString * const UnlockEverythingProductInformationRequestDidSucceedNotification =  @"UnlockEverythingProductInformationRequestDidSucceedNotification";
NSString * const UnlockEverythingProductInformationRequestDidFailNotification =     @"UnlockEverythingProductInformationRequestDidFailNotification";

NSString * const UnlockEverythingPaymentRequestDidSucceedNotification =             @"UnlockEverythingPaymentRequestDidSucceedNotification";
NSString * const UnlockEverythingPaymentRequestDidFailNotification =                @"UnlockEverythingPaymentRequestDidFailNotification";
NSString * const UnlockEverythingPaymentRequestWasDeferredNotification =            @"UnlockEverythingPaymentRequestWasDeferredNotification";

NSString * const UnlockEverythingRestorePurchaseDidSucceedNotification =            @"UnlockEverythingRestorePurchaseDidSucceedNotification";
NSString * const UnlockEverythingRestorePurchaseDidFailNotification =               @"UnlockEverythingRestorePurchaseDidFailNotification";

static NSString * const kStoreKitProductIdentifier = @"com.philliptharris.huckleberryfinn.unlock";
static NSString * const kKeychainPassword = @"UnlockEverything";

@interface UnlockEverythingKit () <SKProductsRequestDelegate>

@property (nonatomic, assign) BOOL successfullyRestoredUnlockEverythingPurchase;

@end

@implementation UnlockEverythingKit

//===============================================
#pragma mark -
#pragma mark Initialization
//===============================================

+ (instancetype)shared {
    static dispatch_once_t pred;
    static UnlockEverythingKit *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[UnlockEverythingKit alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _userHasUnlockedEverything = [self hasTheUserUnlockedEverything];
        
        [self requestProductInformation];
    }
    return self;
}

//===============================================
#pragma mark -
#pragma mark Product Information
//===============================================

- (void)requestProductInformation {
    
    if ([SKPaymentQueue canMakePayments]) {
        
        NSLog(@"🔓 | SKProductsRequest | 📡");
        
        self.currentlyRequestingProductInformation = YES;
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kStoreKitProductIdentifier]];
        request.delegate = self;
        [request start];
    }
    else {
        
        NSLog(@"🔓 | User is not allowed to make payments");
        
        if ([self.delegate respondsToSelector:@selector(productInformationRequestDidFail)]) {
            [self.delegate productInformationRequestDidFail];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingProductInformationRequestDidFailNotification object:self userInfo:nil];
    }
}

//===============================================
#pragma mark SKProductsRequestDelegate
//===============================================

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    self.currentlyRequestingProductInformation = NO;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productIdentifier LIKE %@", kStoreKitProductIdentifier];
    NSArray *results = [response.products filteredArrayUsingPredicate:predicate];
    SKProduct *matchingProduct = [results firstObject];
    
    if (matchingProduct) {
        
        NSLog(@"🔓 | SKProductsRequest | ✅");
        
        self.product = matchingProduct;
        
        if ([self.delegate respondsToSelector:@selector(productInformationRequestDidSucceed)]) {
            [self.delegate productInformationRequestDidSucceed];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingProductInformationRequestDidSucceedNotification object:self userInfo:nil];
    }
    else {
        NSLog(@"🔓 | SKProductsRequest | ❌");
        
        if ([self.delegate respondsToSelector:@selector(productInformationRequestDidFail)]) {
            [self.delegate productInformationRequestDidFail];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingProductInformationRequestDidFailNotification object:self userInfo:nil];
    }
}

//===============================================
#pragma mark Formatted Product Price
//===============================================

- (NSString *)formattedProductPrice {
    if (_formattedProductPrice) {
        return _formattedProductPrice;
    }
    
    if (!self.product) {
        return nil;
    }
    
    // This is sample code from the documentation of the price property of SKProduct.
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:self.product.price];
    //
    
    _formattedProductPrice = formattedString;
    return _formattedProductPrice;
}

//===============================================
#pragma mark -
#pragma mark Purchase
//===============================================

- (void)requestPayment {
    
    if (!self.product) {
        
        if ([self.delegate respondsToSelector:@selector(paymentRequestDidFail)]) {
            [self.delegate paymentRequestDidFail];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingPaymentRequestDidFailNotification object:self userInfo:nil];
        
        return;
    }
    
    NSLog(@"🔓 | Requesting payment...");
    SKPayment *myPayment = [SKMutablePayment paymentWithProduct:self.product];
    [[SKPaymentQueue defaultQueue] addPayment:myPayment];
}

- (void)restorePurchase {
    NSLog(@"🔓 | Restoring past purchases...");
    self.successfullyRestoredUnlockEverythingPurchase = NO;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    NSLog(@"asdf");
}

//===============================================
#pragma mark -
#pragma mark SKPaymentTransactionObserver
//===============================================

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:kStoreKitProductIdentifier]) {
            [self logTransactionStateOfTransaction:transaction];
            switch (transaction.transactionState) {
                case SKPaymentTransactionStatePurchased:
                    [self handleTransactionPurchased:transaction];
                    [queue finishTransaction:transaction];
                    break;
                case SKPaymentTransactionStateFailed:
                    [self handleTransactionFailed:transaction];
                    [queue finishTransaction:transaction];
                    break;
                case SKPaymentTransactionStateRestored:
                    [self handleTransactionRestored:transaction];
                    [queue finishTransaction:transaction];
                    break;
                case SKPaymentTransactionStatePurchasing:
                    [self handleTransactionPurchasing:transaction];
                    break;
                case SKPaymentTransactionStateDeferred:
                    [self handleTransactionDeferred:transaction];
                    break;
                default:
                    break;
            }
        }
        else {
            NSLog(@"🔓 | WILL NOT HANDLE TRANSACTION UPDATES FOR OTHER PRODUCTS | %@", transaction.payment.productIdentifier);
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
    NSLog(@"🔓 | Restore Completed Transactions Finished");
    
    if (!self.successfullyRestoredUnlockEverythingPurchase) {
        
        if ([self.delegate respondsToSelector:@selector(restorePurchaseDidFail)]) {
            [self.delegate restorePurchaseDidFail];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingRestorePurchaseDidFailNotification object:self userInfo:nil];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    
    NSLog(@"🔓 | Restore Completed Transactions Failed | %@", error.localizedDescription);
    
    //
    // If restore fails, will the "paymentQueueRestoreCompletedTransactionsFinished" method also be called? (NO)
    // If restore fails, will the updatedTransactions method with state SKPaymentTransactionStateFailed also be called (NO)
    //
    
    if ([self.delegate respondsToSelector:@selector(restorePurchaseDidFail)]) {
        [self.delegate restorePurchaseDidFail];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingRestorePurchaseDidFailNotification object:self userInfo:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *productIdentifier = transaction.payment.productIdentifier;
        NSLog(@"🔓 | Transaction removed from queue | %@", productIdentifier);
    }
}

//===============================================
#pragma mark -
#pragma mark Handle Transaction Updates
//===============================================

- (NSString *)displayStringForTransactionState:(SKPaymentTransactionState)transactionState {
    switch (transactionState) {
        case SKPaymentTransactionStatePurchased: return @"Purchased";
        case SKPaymentTransactionStateFailed: return @"Failed";
        case SKPaymentTransactionStateRestored: return @"Restored";
        case SKPaymentTransactionStatePurchasing: return @"Purchasing";
        case SKPaymentTransactionStateDeferred: return @"Deferred";
        default: return @"";
    }
}

- (void)logTransactionStateOfTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"🔓 | %@ | %@", [self displayStringForTransactionState:transaction.transactionState], transaction.payment.productIdentifier);
}

- (void)handleTransactionPurchased:(SKPaymentTransaction *)transaction {
    
    [self addProofOfPurchaseToKeychain];
    
    if ([self.delegate respondsToSelector:@selector(paymentRequestDidSucceed)]) {
        [self.delegate paymentRequestDidSucceed];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingPaymentRequestDidSucceedNotification object:self userInfo:nil];
}

- (void)handleTransactionFailed:(SKPaymentTransaction *)transaction {
    
    NSLog(@"🔓 | Failure Reason: %@", transaction.error.localizedDescription);
    
    if ([self.delegate respondsToSelector:@selector(paymentRequestDidFail)]) {
        [self.delegate paymentRequestDidFail];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingPaymentRequestDidFailNotification object:self userInfo:nil];
}

- (void)handleTransactionRestored:(SKPaymentTransaction *)transaction {
    
    self.successfullyRestoredUnlockEverythingPurchase = YES;
    
    [self addProofOfPurchaseToKeychain];
    
    if ([self.delegate respondsToSelector:@selector(restorePurchaseDidSucceed)]) {
        [self.delegate restorePurchaseDidSucceed];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingRestorePurchaseDidSucceedNotification object:self userInfo:nil];
}

- (void)handleTransactionPurchasing:(SKPaymentTransaction *)transaction {
}

- (void)handleTransactionDeferred:(SKPaymentTransaction *)transaction {
    
    if ([self.delegate respondsToSelector:@selector(paymentRequestWasDeferred)]) {
        [self.delegate paymentRequestWasDeferred];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UnlockEverythingPaymentRequestWasDeferredNotification object:self userInfo:nil];
}

//===============================================
#pragma mark -
#pragma mark 🔑 Keychain
//===============================================

- (BOOL)hasTheUserUnlockedEverything {
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:kStoreKitProductIdentifier forKey:(__bridge id)kSecAttrService];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    CFDictionaryRef result = NULL;
    SecItemCopyMatching((CFDictionaryRef)CFBridgingRetain(query), (CFTypeRef *)&result);
    NSData *data = (__bridge NSData *)(result);
    
    if (!data) {
        NSLog(@"🔓.🔑 | No proof of purchase was found in the Keychain");
        return NO;
    }
    else {
        
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if ([string isEqualToString:kKeychainPassword]) {
            NSLog(@"🔓.🔑 | Proof of purchase found in Keychain");
            return YES;
        }
        else {
            NSLog(@"🔓.🔑 | Data found in Keychain, but password does not match.");
            return NO;
        }
    }
}

- (void)addProofOfPurchaseToKeychain {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [dict setObject:kStoreKitProductIdentifier forKey:(__bridge id)kSecAttrService];
    [dict setObject:[kKeychainPassword dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)CFBridgingRelease(kSecValueData)];
    
    SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    
    self.userHasUnlockedEverything = YES;
    
    NSLog(@"🔓.🔑 | Added proof of purchase to Keychain");
}

- (void)removeProofOfPurchaseForTestingPurposes {
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:kStoreKitProductIdentifier forKey:(__bridge id)kSecAttrService];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    SecItemDelete((__bridge CFDictionaryRef)(query));
    
    self.userHasUnlockedEverything = NO;
    
    NSLog(@"🔓.🔑 | Removed proof of purchase from Keychain");
}

@end
