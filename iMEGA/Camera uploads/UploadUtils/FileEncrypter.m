
#import "FileEncrypter.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSError+CameraUpload.h"

static const NSUInteger EncryptionProposedChunkSizeForTruncating = 100 * 1024 * 1024;
static const NSUInteger EncryptionMinimumChunkSize = 5 * 1024 * 1024;
static const NSUInteger EncryptionProposedChunkSizeWithoutTruncating = 1024 * 1024 * 1024;

@interface FileEncrypter ()

@property (strong, nonatomic) NSURL *outputDirectoryURL;
@property (nonatomic) unsigned long long fileSize;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;
@property (nonatomic) BOOL shouldTruncateFile;

@end

@implementation FileEncrypter

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputDirectoryURL:(NSURL *)outputDirectoryURL shouldTruncateInputFile:(BOOL)shouldTruncateInputFile {
    self = [super init];
    if (self) {
        _outputDirectoryURL = outputDirectoryURL;
        _mediaUpload = mediaUpload;
        _shouldTruncateFile = shouldTruncateInputFile;
    }

    return self;
}

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSDictionary<NSString *, NSURL *> *chunkURLsKeyedByUploadSuffix, NSError *error))completion {
    NSError *error;
    [NSFileManager.defaultManager createDirectoryAtPath:self.outputDirectoryURL.path withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSDictionary<NSFileAttributeKey, id> *attributeDict = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error];
    
    self.fileSize = attributeDict.fileSize;
    unsigned long long deviceFreeSize = [NSFileManager.defaultManager deviceFreeSize];
    
    MEGALogDebug(@"[Camera Upload] input file size %.2f M, device free size %.2f M", self.fileSize / 1024.0 / 1024.0, deviceFreeSize / 1024.0 / 1024.0);
    
    if (error) {
        completion(NO, 0, nil, error);
        return;
    }
    
    if (self.shouldTruncateFile) {
        if (deviceFreeSize < EncryptionMinimumChunkSize) {
            completion(NO, 0, nil, [NSError mnz_cameraUploadNoEnoughFreeSpaceError]);
            return;
        }
        
        if (![NSFileManager.defaultManager isWritableFileAtPath:fileURL.path]) {
            completion(NO, 0, nil, [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoFileWritePermission userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"no write permission for file %@", fileURL]}]);
            return;
        }
    } else {
        if (deviceFreeSize < self.fileSize) {
            completion(NO, 0, nil, [NSError mnz_cameraUploadNoEnoughFreeSpaceError]);
            return;
        }
    }

    NSUInteger chunkSize = [self calculateChunkSizeByDeviceFreeSize:deviceFreeSize];
    MEGALogDebug(@"[Camera Upload] encryption chunk size %.2f M", chunkSize / 1024.0 / 1024.0);
    NSDictionary *chunkURLsKeyedByUploadSuffix = [self encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:fileURL chunkSize:chunkSize error:&error];
    if (error) {
        completion(NO, 0, nil, error);
    } else {
        completion(YES, self.fileSize, chunkURLsKeyedByUploadSuffix, nil);
    }
}

- (NSDictionary<NSString *, NSURL *> *)encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:(NSURL *)fileURL chunkSize:(NSUInteger)chunkSize error:(NSError **)error {
    NSError *positionError;
    NSArray<NSNumber *> *chunkPositions = [self calculteChunkPositionsForFileAtURL:fileURL chunkSize:chunkSize error:&positionError];
    if (positionError) {
        if (error != NULL) {
            *error = positionError;
        }
        
        return @{};
    }

    MEGALogDebug(@"[Camera Upload] reversed chunk positions %@", chunkPositions);
    
    NSMutableDictionary<NSString *, NSURL *> *chunksDict = [NSMutableDictionary dictionary];
    NSFileHandle *fileHandle;
    if (self.shouldTruncateFile) {
         fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileURL.path];
    }
    
    unsigned long long lastPosition = self.fileSize;
    for (NSInteger chunkIndex = chunkPositions.count - 1; chunkIndex >= 0; chunkIndex --) {
        NSNumber *position = chunkPositions[chunkIndex];
        if (position.unsignedLongLongValue == lastPosition) {
            continue;
        }
        
        unsigned length = (unsigned)(lastPosition - position.unsignedLongLongValue);
        NSString *chunkName = [NSString stringWithFormat:@"chunk%ld", (long)chunkIndex];
        NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:chunkName];
        NSString *suffix;
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:position.unsignedLongLongValue length:&length outputFilePath:chunkURL.path urlSuffix:&suffix adjustsSizeOnly:NO]) {
            chunksDict[suffix] = chunkURL;
            lastPosition = position.unsignedLongLongValue;
            if (self.shouldTruncateFile && fileHandle) {
                [fileHandle truncateFileAtOffset:position.unsignedLongLongValue];
            }
        } else {
            if (error != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"error occurred when to encrypt file %@", fileURL.lastPathComponent];
                *error = [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorEncryption userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            }
            
            return @{};
        }
    }
    
    if (self.shouldTruncateFile) {
        [NSFileManager.defaultManager removeItemIfExistsAtURL:fileURL];
    }
    
    return chunksDict;
}

- (NSArray<NSNumber *> *)calculteChunkPositionsForFileAtURL:(NSURL *)fileURL chunkSize:(NSUInteger)chunkSize error:(NSError **)error {
    NSMutableArray<NSNumber *> *chunkPositions = [NSMutableArray arrayWithObject:@(0)];
    unsigned chunkSizeToBeAdjusted = (unsigned)chunkSize;
    unsigned long long startPosition = 0;
    while (startPosition < self.fileSize) {
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:startPosition length:&chunkSizeToBeAdjusted outputFilePath:nil urlSuffix:nil adjustsSizeOnly:YES]) {
            startPosition = startPosition + chunkSizeToBeAdjusted;
            [chunkPositions addObject:@(startPosition)];
        } else {
            if (error != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"error occurred when to calculate chunk position for file %@", fileURL.lastPathComponent];
                *error = [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorCalculateEncryptionChunkPositions userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            }
            
            return @[];
        }
    }
    
    return [chunkPositions copy];
}

/**
 Calculate the chunk size according to the device free space and whether to truncate input file during encryption

 @param deviceFreeSize available space in the device in bytes
 @return proper chunk size to encrypt file, measured in bytes
 */
- (NSUInteger)calculateChunkSizeByDeviceFreeSize:(unsigned long long)deviceFreeSize {
    if (self.shouldTruncateFile) {
        NSUInteger size = MIN(EncryptionProposedChunkSizeForTruncating, (NSUInteger)self.fileSize);
        if (deviceFreeSize > size * 5) {
            return size;
        } else if (deviceFreeSize > size) {
            return size / 5;
        } else {
            return (NSUInteger)(deviceFreeSize / 5);
        }
    } else {
        return EncryptionProposedChunkSizeWithoutTruncating;
    }
}

@end
