//
//  UnlockEverythingKit.h
//  UnlockEverythingKit
//
//  Created by Phillip Harris on 5/8/15.
//  Copyright (c) 2015 Phillip Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

@import StoreKit;

@protocol UnlockEverythingDelegate;

extern NSString * const UnlockEverythingProductInformationRequestDidSucceedNotification;
extern NSString * const UnlockEverythingProductInformationRequestDidFailNotification;

extern NSString * const UnlockEverythingPaymentRequestDidSucceedNotification;
extern NSString * const UnlockEverythingPaymentRequestDidFailNotification;
extern NSString * const UnlockEverythingPaymentRequestWasDeferredNotification;

extern NSString * const UnlockEverythingRestorePurchaseDidSucceedNotification;
extern NSString * const UnlockEverythingRestorePurchaseDidFailNotification;

@interface UnlockEverythingKit : NSObject <SKPaymentTransactionObserver>

@property (nonatomic, strong) SKProduct *product;
@property (nonatomic, strong) NSString *formattedProductPrice;
@property (nonatomic, assign) BOOL currentlyRequestingProductInformation;
@property (nonatomic, assign) BOOL userHasUnlockedEverything;
@property (nonatomic, weak) id <UnlockEverythingDelegate> delegate;

+ (instancetype)shared;

- (void)requestProductInformation;
- (void)requestPayment;
- (void)restorePurchase;
- (void)removeProofOfPurchaseForTestingPurposes;

@end


@protocol UnlockEverythingDelegate <NSObject>

@optional

- (void)productInformationRequestDidSucceed;
- (void)productInformationRequestDidFail;

- (void)paymentRequestDidSucceed;
- (void)paymentRequestDidFail;
- (void)paymentRequestWasDeferred;

- (void)restorePurchaseDidSucceed;
- (void)restorePurchaseDidFail;

@end