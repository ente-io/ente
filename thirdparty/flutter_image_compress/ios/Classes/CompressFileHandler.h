//
// Created by cjl on 2018/9/8.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface CompressFileHandler : NSObject
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)handleCompressFileToFile:(FlutterMethodCall *)call result:(FlutterResult)result;
@end
