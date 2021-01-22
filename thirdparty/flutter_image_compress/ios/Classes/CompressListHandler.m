//
//  CompressListHandler.m
//  flutter_image_compress
//
//  Created by cjl on 2018/9/8.
//

#import <Flutter/Flutter.h>
#import "CompressListHandler.h"
#import "CompressHandler.h"
#import "SYMetadata.h"

@implementation CompressListHandler

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSArray *args = call.arguments;
    FlutterStandardTypedData *list = args[0];
    int minWidth = [args[1] intValue];
    int minHeight = [args[2] intValue];
    int quality = [args[3] intValue];
    int rotate = [args[4] intValue];
    int formatType = [args[6] intValue];

    BOOL keepExif = [args[7] boolValue];

    NSData *data = [list data];
    NSData *compressedData = [CompressHandler compressWithData:data minWidth:minWidth minHeight:minHeight quality:quality rotate:rotate format:formatType];

    if (keepExif) {
        SYMetadata *metadata = [SYMetadata metadataWithImageData:data];
        metadata.orientation = @0;
        compressedData = [SYMetadata dataWithImageData:compressedData andMetadata:metadata];
    }

    result([FlutterStandardTypedData typedDataWithBytes:compressedData]);
}


@end
