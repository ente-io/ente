//
// Created by Caijinglong on 2020/3/20.
//

#import "PMRequestTypeUtils.h"

#define PM_TYPE_IMAGE 1
#define PM_TYPE_VIDEO 1<<1
#define PM_TYPE_AUDIO 1<<2

@implementation PMRequestTypeUtils {

}

+ (BOOL)checkContainsType:(int)type targetType:(int)targetType {
  return (type & targetType) == targetType;
}

+ (BOOL)containsImage:(int)type {
  return [self checkContainsType:type targetType:PM_TYPE_IMAGE];
}

+ (BOOL)containsVideo:(int)type {
  return [self checkContainsType:type targetType:PM_TYPE_VIDEO];
}

+ (BOOL)containsAudio:(int)type {
  return [self checkContainsType:type targetType:PM_TYPE_AUDIO];
}

@end