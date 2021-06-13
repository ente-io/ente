//
// Created by Caijinglong on 2019-07-16.
//

#import "PMLogUtils.h"


@implementation PMLogUtils {

}
+ (instancetype)sharedInstance {
    static PMLogUtils *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        _sharedInstance.isLog = NO;
    });

    return _sharedInstance;
}

- (void)info:(NSString *)info {
    if (!self.isLog) {
        return;
    }
    NSLog(@"PhotoManager info: %@", info);
}

- (void)debug:(NSString *)info {
    if (!self.isLog) {
        return;
    }
    NSLog(@"PhotoManager debug: %@", info);
}

@end
