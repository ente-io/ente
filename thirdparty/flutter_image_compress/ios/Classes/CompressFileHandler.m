//
// Created by cjl on 2018/9/8.
//

#import "CompressFileHandler.h"
#import "CompressHandler.h"
#import "SYMetadata.h"
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>
#import <SDWebImage/SDWebImage.h>

@implementation CompressFileHandler {

}
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {

    NSArray *args = call.arguments;
    NSString *path = args[0];
    int minWidth = [args[1] intValue];
    int minHeight = [args[2] intValue];
    int quality = [args[3] intValue];
    int rotate = [args[4] intValue];

    int formatType = [args[6] intValue];
    BOOL keepExif = [args[7] boolValue];

    
    UIImage *img;
    
    NSURL *imageUrl = [NSURL fileURLWithPath:path];
    NSData *nsdata = [NSData dataWithContentsOfURL:imageUrl];
    
    NSString *imageType = [self mimeTypeByGuessingFromData:nsdata];
    
    //  NSLog(@" nsdata length: %@", imageType);
    
    SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
    // [[SDImageCodersManager sharedManager] addCoder:webPCoder];
    
    if(imageType == @"image/webp") {
    img = [[SDImageWebPCoder sharedCoder] decodedImageWithData:nsdata options:nil];
    } else {
        img = [UIImage imageWithData:nsdata];
    }


    NSData *data = [CompressHandler compressWithUIImage:img minWidth:minWidth minHeight:minHeight quality:quality rotate:rotate format:formatType];

    if (keepExif) {
        SYMetadata *metadata = [SYMetadata metadataWithFileURL:[NSURL fileURLWithPath:path]];
        metadata.orientation = @0;
        data = [SYMetadata dataWithImageData:data andMetadata:metadata];
    }

    result([FlutterStandardTypedData typedDataWithBytes:data]);
}

- (void)handleCompressFileToFile:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSArray *args = call.arguments;
    NSString *path = args[0];
    int minWidth = [args[1] intValue];
    int minHeight = [args[2] intValue];
    int quality = [args[3] intValue];
    NSString *targetPath = args[4];
    int rotate = [args[5] intValue];

    int formatType = [args[7] intValue];
    BOOL keepExif = [args[8] boolValue];

    
    UIImage *img;
    
    NSURL *imageUrl = [NSURL fileURLWithPath:path];
    NSData *nsdata = [NSData dataWithContentsOfURL:imageUrl];
    
    NSString *imageType = [self mimeTypeByGuessingFromData:nsdata];
    
    //  NSLog(@" nsdata length: %@", imageType);
    
    SDImageWebPCoder *webPCoder = [SDImageWebPCoder sharedCoder];
    // [[SDImageCodersManager sharedManager] addCoder:webPCoder];
    
    if(imageType == @"image/webp") {
    img = [[SDImageWebPCoder sharedCoder] decodedImageWithData:nsdata options:nil];
    } else {
        img = [UIImage imageWithData:nsdata];
    }
    
    NSData *data = [CompressHandler compressDataWithUIImage:img minWidth:minWidth minHeight:minHeight quality:quality rotate:rotate format:formatType];

    if (keepExif) {
        SYMetadata *metadata = [SYMetadata metadataWithFileURL:[NSURL fileURLWithPath:path]];
        metadata.orientation = @0;
        data = [SYMetadata dataWithImageData:data andMetadata:metadata];
    }

    [data writeToURL:[[NSURL alloc] initFileURLWithPath:targetPath] atomically:YES];

    result(targetPath);
}


- (NSString *)mimeTypeByGuessingFromData:(NSData *)data {

    char bytes[12] = {0};
    [data getBytes:&bytes length:12];

    const char bmp[2] = {'B', 'M'};
    const char gif[3] = {'G', 'I', 'F'};
    const char swf[3] = {'F', 'W', 'S'};
    const char swc[3] = {'C', 'W', 'S'};
    const char jpg[3] = {0xff, 0xd8, 0xff};
    const char psd[4] = {'8', 'B', 'P', 'S'};
    const char iff[4] = {'F', 'O', 'R', 'M'};
    const char webp[4] = {'R', 'I', 'F', 'F'};
    const char ico[4] = {0x00, 0x00, 0x01, 0x00};
    const char tif_ii[4] = {'I','I', 0x2A, 0x00};
    const char tif_mm[4] = {'M','M', 0x00, 0x2A};
    const char png[8] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
    const char jp2[12] = {0x00, 0x00, 0x00, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a};


    if (!memcmp(bytes, bmp, 2)) {
        return @"image/x-ms-bmp";
    } else if (!memcmp(bytes, gif, 3)) {
        return @"image/gif";
    } else if (!memcmp(bytes, jpg, 3)) {
        return @"image/jpeg";
    } else if (!memcmp(bytes, psd, 4)) {
        return @"image/psd";
    } else if (!memcmp(bytes, iff, 4)) {
        return @"image/iff";
    } else if (!memcmp(bytes, webp, 4)) {
        return @"image/webp";
    } else if (!memcmp(bytes, ico, 4)) {
        return @"image/vnd.microsoft.icon";
    } else if (!memcmp(bytes, tif_ii, 4) || !memcmp(bytes, tif_mm, 4)) {
        return @"image/tiff";
    } else if (!memcmp(bytes, png, 8)) {
        return @"image/png";
    } else if (!memcmp(bytes, jp2, 12)) {
        return @"image/jp2";
    }

    return @"application/octet-stream"; // default type

}
@end
