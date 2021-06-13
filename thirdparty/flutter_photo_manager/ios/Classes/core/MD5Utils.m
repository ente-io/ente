//
// Created by Caijinglong on 2018/9/11.
//

#import "MD5Utils.h"

@implementation MD5Utils
#define CC_MD5_DIGEST_LENGTH 16

+ (NSString *)getmd5WithString:(NSString *)string {
    const char *original_str = [string UTF8String];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint) strlen(original_str), digist);
    NSMutableString *outPutStr = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [outPutStr appendFormat:@"%02x", digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
}

+ (NSString *)getMD5WithData:(NSData *)data {
    const char *original_str = (const char *) [data bytes];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint) strlen(original_str), digist);
    NSMutableString *outPutStr = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [outPutStr appendFormat:@"%02x", digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }

    //也可以定义一个字节数组来接收计算得到的MD5值
    //    Byte byte[16];
    //    CC_MD5(original_str, strlen(original_str), byte);
    //    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    //    for(int  i = 0; i<CC_MD5_DIGEST_LENGTH;i++){
    //        [outPutStr appendFormat:@"%02x",byte[i]];
    //    }
    //    [temp release];

    return [outPutStr lowercaseString];

}

+ (NSString *)getFileMD5WithPath:(NSString *)path {
    return (__bridge_transfer NSString *) FileMD5HashCreateWithPath((__bridge CFStringRef) path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,
        size_t chunkSizeForReadingData) {

    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;

    // Get the file URL
    CFURLRef fileURL =
            CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                    (CFStringRef) filePath,
                    kCFURLPOSIXPathStyle,
                    (Boolean) false);

    CC_MD5_CTX hashObject;
    bool hasMoreData = true;
    bool didSucceed;

    if (!fileURL) goto done;

    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
            (CFURLRef) fileURL);
    if (!readStream) goto done;
    didSucceed = (bool) CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;

    // Initialize the hash object
    CC_MD5_Init(&hashObject);

    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }

    // Feed the data to the hash object
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                (UInt8 *) buffer,
                (CFIndex) sizeof(buffer));
        if (readBytesCount == -1)break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject, (const void *) buffer, (CC_LONG) readBytesCount);
    }

    // Check if the read operation succeeded
    didSucceed = !hasMoreData;

    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);

    // Abort if the read operation failed
    if (!didSucceed) goto done;

    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int) (digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
            (const char *) hash,
            kCFStringEncodingUTF8);

    done:

    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

@end