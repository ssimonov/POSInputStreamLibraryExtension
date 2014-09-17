//
//  POSLocking.h
//  RoundMe
//
//  Created by Vlad Mihaylenko on 25/07/14.
//  Copyright (c) 2014 Vlad Mihaylenko. All rights reserved.
//

#import <Foundation/Foundation.h>


FOUNDATION_EXTERN NSString * const POSBlobInputStreamAssetDataSourceErrorDomain;

#define kIOS5x (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_5_1)

typedef NS_ENUM(NSInteger, POSBlobInputStreamAssetDataSourceErrorCode) {
    POSBlobInputStreamAssetDataSourceErrorCodeOpen = 0,
    POSBlobInputStreamAssetDataSourceErrorCodeRead = 1
};


@protocol Locking <NSLocking>

- (BOOL)waitWithTimeout:(dispatch_time_t)timeout;

@end

@interface GCDLock : NSObject <Locking>

- (void)lock;
- (void)unlock;
- (BOOL)waitWithTimeout:(dispatch_time_t)timeout;

@end

@interface OKLock : NSObject <Locking>

- (void)lock;
- (void)unlock;
- (BOOL)waitWithTimeout:(dispatch_time_t)timeout;

@end

@interface DummyLock : NSObject <Locking>

- (void)lock;
- (void)unlock;
- (BOOL)waitWithTimeout:(dispatch_time_t)timeout;

@end
