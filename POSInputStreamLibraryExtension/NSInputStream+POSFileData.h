//
//  NSInputStream+POS.h
//  POSBlobInputStreamLibrary
//
//  Created by Pavel Osipov on 17.07.13.
//  Copyright (c) 2013 Pavel Osipov. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface NSInputStream (POSExtension)

+ (NSInputStream *)pos_inputStreamWithFilePath:(NSString*)filePath;
+ (NSInputStream *)pos_inputStreamWithFileAtPath:(NSString*)filePath
                                    asynchronous:(BOOL)asynchronous;

+ (NSInputStream *)pos_inputStreamForCFNetworkWithFilePath:(NSString*)filePath;

@end
