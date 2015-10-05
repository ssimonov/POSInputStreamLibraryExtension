//
//  POSInputStreamMP4DataSource.h
//  POSInputStreamLibraryExtension
//
//  Created by Сергей Симонов on 03/09/14.
//  Copyright (c) 2014 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "POSBlobInputStreamDataSource.h"

/// These are the only types of errors which raises POSBlobInputStreamAssetDataSource.
typedef NS_ENUM(NSInteger, POSBlobInputStreamFileDataSourceErrorCode) {
    POSBlobInputStreamFileDataSourceErrorCodeOpen = 0,
    POSBlobInputStreamFileDataSourceErrorCodeRead = 1
};

@interface POSInputStreamFileDataSource : NSObject <POSBlobInputStreamDataSource>

@property (nonatomic, assign, getter = shouldOpenSynchronously) BOOL openSynchronously;

- (id)initWithFilePath:(NSString*)filePath;

@end
