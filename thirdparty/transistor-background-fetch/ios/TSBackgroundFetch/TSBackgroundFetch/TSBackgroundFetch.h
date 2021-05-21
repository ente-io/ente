//
//  RNBackgroundFetchManager.h
//  RNBackgroundFetch
//
//  Created by Christopher Scott on 2016-08-02.
//  Copyright © 2016 Christopher Scott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BackgroundTasks/BackgroundTasks.h>

@interface TSBackgroundFetch : NSObject

@property (nonatomic) BOOL stopOnTerminate;
@property (readonly) BOOL configured;
@property (readonly) BOOL active;
@property (readonly) NSString *fetchTaskId;
@property (copy) void (^completionHandler)(UIBackgroundFetchResult);
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

+ (TSBackgroundFetch *)sharedInstance;

-(void) didFinishLaunching;
-(void) registerAppRefreshTask;
-(void) registerBGProcessingTask:(NSString*)identifier;

-(void) configure:(NSTimeInterval)delay callback:(void(^)(UIBackgroundRefreshStatus status))callback;

-(NSError*) scheduleProcessingTaskWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic callback:(void (^)(NSString* taskId, BOOL timeout))callback;

-(NSError*) scheduleProcessingTaskWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic requiresExternalPower:(BOOL)requiresExternalPower requiresNetworkConnectivity:(BOOL)requiresNetworkConnectivity callback:(void (^)(NSString* taskId, BOOL timeout))callback;

-(void) addListener:(NSString*)componentName callback:(void (^)(NSString* componentName))callback;
-(void) addListener:(NSString*)componentName callback:(void (^)(NSString* componentName))callback timeout:(void (^)(NSString* componentName))timeout;
-(void) removeListener:(NSString*)componentName;
-(BOOL) hasListener:(NSString*)componentName;

-(NSError*) start:(NSString*)identifier;
-(void) stop:(NSString*)identifier;
-(void) finish:(NSString*)tag;
-(void) status:(void(^)(UIBackgroundRefreshStatus status))callback;

// @deprecated API
-(void) performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))handler applicationState:(UIApplicationState)state;
@end

