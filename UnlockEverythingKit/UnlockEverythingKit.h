//
//  UnlockEverythingKit.h
//  UnlockEverythingKit
//
//  Created by Phillip Harris on 5/8/15.
//  Copyright (c) 2015 Phillip Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

@import StoreKit;

@protocol UnlockEverythingKitObserver;

extern NSString * const UnlockEverythingProductInformationRequestDidSucceedNotification;
extern NSString * const UnlockEverythingProductInformationRequestDidFailNotification;

extern NSString * const UnlockEverythingPaymentRequestDidSucceedNotification;
extern NSString * const UnlockEverythingPaymentRequestDidFailNotification;
extern NSString * const UnlockEverythingPaymentRequestWasDeferredNotification;

extern NSString * const UnlockEverythingRestorePurchaseDidSucceedNotification;
extern NSString * const UnlockEverythingRestorePurchaseDidFailNotification;

@interface UnlockEverythingKit : NSObject <SKPaymentTransactionObserver>

@property (nonatomic, strong) NSString *storeKitProductIdentifier;
@property (nonatomic, strong) SKProduct *product;
@property (nonatomic, strong) NSString *formattedProductPrice;
@property (nonatomic, assign) BOOL currentlyRequestingProductInformation;
@property (nonatomic, assign) BOOL userHasUnlockedEverything;

+ (instancetype)shared;

- (void)requestProductInformation;
- (void)requestPayment;
- (void)restorePurchase;
- (void)removeProofOfPurchaseForTestingPurposes;

- (void)addObserver:(id <UnlockEverythingKitObserver>)observer;
- (void)removeObserver:(id <UnlockEverythingKitObserver>)observer;

@end


@protocol UnlockEverythingKitObserver <NSObject>

@optional

- (void)productInformationRequestDidSucceed;
- (void)productInformationRequestDidFail;

/// iOS will show an alert to the user, so you don't have to.
- (void)paymentRequestDidSucceed;
/// iOS does not show an alert for this event.
- (void)paymentRequestDidFail:(NSString *)reason;
/// Not sure if iOS shows an alert for this event.
- (void)paymentRequestWasDeferred;

/// iOS does not show an alert for this event.
- (void)restorePurchaseDidSucceed;
/// iOS does not show an alert for this event.
- (void)restorePurchaseDidFail:(NSString *)reason;

@end