//
// Created by Caijinglong on 2018/9/11.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#define FileHashDefaultChunkSizeForReadingData 1024*8 // 8K

@interface MD5Utils :NSObject

//计算NSData 的MD5值
+(NSString*)getMD5WithData:(NSData*)data;

//计算字符串的MD5值，
+(NSString*)getmd5WithString:(NSString*)string;

//计算大文件的MD5值
+(NSString*)getFileMD5WithPath:(NSString*)path;
@end