//
//  POSInputStreamMP4DataSource.m
//  POSInputStreamLibraryExtension
//
//  Created by Сергей Симонов on 03/09/14.
//  Copyright (c) 2014 Pavel Osipov. All rights reserved.
//

#import "POSInputStreamFileDataSource.h"
#import "POSLocking.h"


NSString * const POSBlobInputStreamFileDataSourceErrorDomain = @"com.github.pavelosipov.POSBlobInputStreamFileDataSource";

static uint64_t const kFileCacheBufferSize = 131072;

typedef NS_ENUM(NSInteger, UpdateCacheMode) {
    UpdateCacheModeReopenWhenError,
    UpdateCacheModeFailWhenError
};

#pragma mark - NSError (POSBlobInputStreamFileDataSource)

@interface NSError (POSBlobInputStreamFileDataSource)
+ (NSError *)pos_fileOpenError;
@end

@implementation NSError (POSBlobInputStreamFileDataSource)

+ (NSError *)pos_fileOpenError {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Failed to open file stream." };
    return [NSError errorWithDomain:POSBlobInputStreamFileDataSourceErrorDomain
                               code:POSBlobInputStreamAssetDataSourceErrorCodeOpen
                           userInfo:userInfo];
}

+ (NSError *)pos_fileReadErrorWithPath:(NSString *)filePath reason:(NSError *)reason {
    NSString *description = [NSString stringWithFormat:@"Failed to read asset with URL %@", filePath];
    if (reason) {
        return [NSError errorWithDomain:POSBlobInputStreamFileDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeRead
                               userInfo:@{ NSLocalizedDescriptionKey: description, NSUnderlyingErrorKey: reason }];
    } else {
        return [NSError errorWithDomain:POSBlobInputStreamFileDataSourceErrorDomain
                                   code:POSBlobInputStreamAssetDataSourceErrorCodeRead
                               userInfo:@{ NSLocalizedDescriptionKey: description }];
    }
}

@end

#pragma mark - POSBlobInputStreamAssetDataSource

@interface POSInputStreamFileDataSource ()
@property (nonatomic, readwrite) NSError *error;
@end

@implementation POSInputStreamFileDataSource {
    NSString *_filePath;
    NSFileHandle *_file;
    off_t _fileSize;
    off_t _readOffset;
    uint8_t _fileCache[kFileCacheBufferSize];
    off_t _fileCacheSize;
    off_t _fileCacheOffset;
    off_t _fileCacheInternalOffset;
}

@dynamic openCompleted, hasBytesAvailable, atEnd;

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unexpected deadly init invokation '%@', use %@ instead.",
                                           NSStringFromSelector(_cmd),
                                           NSStringFromSelector(@selector(initWithFilePath:))]
                                 userInfo:nil];
}

- (id)initWithFilePath:(NSString *)filePath {
    NSParameterAssert(filePath);
    if (self = [super init]) {
        _openSynchronously = NO;
        _filePath = filePath;
        _fileCacheSize = 0;
        _fileCacheOffset = 0;
        _fileCacheInternalOffset = 0;
    }
    return self;
}

- (void) dealloc {
    [_file closeFile];
}

#pragma mark - POSBlobInputStreamDataSource

- (BOOL)isOpenCompleted {
    return [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
}

- (void)open {
    if ([self isOpenCompleted]) {
        [self p_open];
    }
}

- (BOOL)hasBytesAvailable {
    return [self p_availableBytesCount] > 0;
}

- (BOOL)isAtEnd {
    return _fileSize <= _readOffset;
}

- (id)propertyForKey:(NSString *)key {
    if (![key isEqualToString:NSStreamFileCurrentOffsetKey]) {
        return nil;
    }
    return @(_readOffset);
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    if (![key isEqualToString:NSStreamFileCurrentOffsetKey]) {
        return NO;
    }
    if (![property isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    const long long requestedOffest = [property longLongValue];
    if (requestedOffest < 0) {
        return NO;
    }
    _readOffset = requestedOffest;
    if ([self isOpenCompleted]) {
        [self p_updateCacheInMode:UpdateCacheModeReopenWhenError];
    }
    return YES;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    NSParameterAssert(buffer);
    NSParameterAssert(maxLength > 0);
    if (self.atEnd) {
        return 0;
    }
    const off_t readResult = MIN(maxLength, [self p_availableBytesCount]);
    memcpy(buffer, _fileCache + _fileCacheInternalOffset, (unsigned long)readResult);
    _fileCacheInternalOffset += readResult;
    const off_t readOffset = _readOffset + readResult;
    NSParameterAssert(readOffset <= _fileSize);
    const BOOL atEnd = readOffset >= _fileSize;
    if (atEnd) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    }
    _readOffset = readOffset;
    if (atEnd) {
        [self didChangeValueForKey:POSBlobInputStreamDataSourceAtEndKeyPath];
    } else if (![self hasBytesAvailable]) {
        [self p_updateCacheInMode:UpdateCacheModeReopenWhenError];
    }
    return (NSInteger)readResult;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)bufferLength {
    return NO;
}

#pragma mark - POSBlobInputStreamDataSource Private

- (void)p_open {
    id<Locking> lock = [self p_lockForOpening];
    [lock lock];
    
    dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool {
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil];
        NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:_filePath];
        if (dict) {
            [self p_updateFile:file withAttributes:dict];
            [self p_updateCacheInMode:UpdateCacheModeFailWhenError];
        } else {
            NSLog(@"Dictionary is empty");
        }
        [lock unlock];
    }});
    
    [lock waitWithTimeout:DISPATCH_TIME_FOREVER];
}

- (void)p_updateFile:(NSFileHandle*) file withAttributes:(NSDictionary*) attributes {
    const BOOL shouldEmitOpenCompletedEvent = [self isOpenCompleted];
    if (shouldEmitOpenCompletedEvent) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
    }
    _file = file;
    _fileSize = [attributes[NSFileSize] longLongValue];
    if (shouldEmitOpenCompletedEvent) {
        [self didChangeValueForKey:POSBlobInputStreamDataSourceOpenCompletedKeyPath];
    }
}

- (void)p_updateCacheInMode:(UpdateCacheMode)mode {
    NSError *readError = nil;
    [_file seekToFileOffset:_readOffset];
    NSData *dataBuffer = [_file readDataOfLength:kFileCacheBufferSize];
    memcpy(_fileCache, [dataBuffer bytes], [dataBuffer length]);
    if ([dataBuffer length] > 0) {
        [self willChangeValueForKey:POSBlobInputStreamDataSourceHasBytesAvailableKeyPath];
        _fileCacheSize = [dataBuffer length];
        _fileCacheOffset = _readOffset;
        _fileCacheInternalOffset = 0;
        [self didChangeValueForKey:POSBlobInputStreamDataSourceHasBytesAvailableKeyPath];
    } else {
        switch (mode) {
            case UpdateCacheModeReopenWhenError: {
                [self p_open];
            } break;
            case UpdateCacheModeFailWhenError: {
                [self setError:[NSError pos_fileReadErrorWithPath:_filePath reason:readError]];
            } break;
        }
    }
}

- (off_t)p_availableBytesCount {
    return _fileCacheSize - _fileCacheInternalOffset;
}

- (id<Locking>)p_lockForOpening {
    if ([self shouldOpenSynchronously]) {
        // If you want open stream synchronously you should do that in some worker thread to avoid deadlock.
        NSParameterAssert(![[NSThread currentThread] isMainThread]);
        return [GCDLock new];
    } else {
        return [DummyLock new];
    }
}

@end
