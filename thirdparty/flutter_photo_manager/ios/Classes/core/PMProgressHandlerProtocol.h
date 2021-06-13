//
// Created by jinglong cai on 2021/4/13.
//

#import <Foundation/Foundation.h>

typedef enum PMProgressState{
  PMProgressStatePrepare = 0,
  PMProgressStateLoading = 1,
  PMProgressStateSuccess = 2,
  PMProgressStateFailed = 3,
} PMProgressState;


@protocol PMProgressHandlerProtocol <NSObject>

- (void)notify:(double)progress state:(PMProgressState)state;

- (void)deinit;

@end