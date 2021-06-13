//
//  PMFileHelper.m
//  photo_manager
//
//  Created by Caijinglong on 2020/1/14.
//

#import "PMFileHelper.h"

@implementation PMFileHelper

+(void)deleteFile:(NSString *)path{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL *isDir = NULL;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory: isDir];
    if(exists){
        [fileManager removeItemAtPath:path error:nil];
    }
}

@end
