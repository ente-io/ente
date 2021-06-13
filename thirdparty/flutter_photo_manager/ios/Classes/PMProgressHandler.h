//
//  PMProgressHandler.h
//  path_provider
//
//  Created by jinglong cai on 2021/1/15.
//

#import <Foundation/Foundation.h>
#import "PMProgressHandlerProtocol.h"
#import "PMImport.h"

NS_ASSUME_NONNULL_BEGIN

@interface PMProgressHandler : NSObject <PMProgressHandlerProtocol>

@property(nonatomic, assign) int channelIndex;

- (void)notify:(double)progress state:(PMProgressState)state;

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index;

- (void)deinit;

@end

NS_ASSUME_NONNULL_END
