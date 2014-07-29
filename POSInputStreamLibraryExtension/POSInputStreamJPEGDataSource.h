//
//  POSInputStreamJPEGDataSource.h
//  POSInputStreamLibrary
//
//  Created by Vlad Mihaylenko on 24/07/14.
//  Copyright (c) 2014 Vlad Mihaylenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "POSBlobInputStreamDataSource.h"


@interface POSInputStreamJPEGDataSource : NSObject <POSBlobInputStreamDataSource>

@property (nonatomic, assign, getter = shouldOpenSynchronously) BOOL openSynchronously;

- (id) initWithFilePath:(NSString*) filePath;

@end
