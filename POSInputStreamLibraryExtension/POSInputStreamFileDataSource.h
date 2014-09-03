//
//  POSInputStreamMP4DataSource.h
//  POSInputStreamLibraryExtension
//
//  Created by Сергей Симонов on 03/09/14.
//  Copyright (c) 2014 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "POSBlobInputStreamDataSource.h"


@interface POSInputStreamFileDataSource : NSObject <POSBlobInputStreamDataSource>

@property (nonatomic, assign, getter = shouldOpenSynchronously) BOOL openSynchronously;

- (id)initWithFilePath:(NSString*)filePath;

@end
