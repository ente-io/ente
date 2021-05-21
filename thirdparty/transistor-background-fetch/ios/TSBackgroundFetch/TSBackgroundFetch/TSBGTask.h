//
//  TSBGTask.h
//  TSBackgroundFetch
//
//  Created by Christopher Scott on 2020-01-23.
//  Copyright © 2020 Christopher Scott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BackgroundTasks/BackgroundTasks.h>

@interface TSBGTask : NSObject

@property (nonatomic) BGTask* task API_AVAILABLE(ios(13.0));

@property (nonatomic) NSString* identifier;
@property (copy) void (^callback)(NSString*, BOOL);
@property (nonatomic) NSTimeInterval delay;
@property (nonatomic, readonly) BOOL executed;
@property (nonatomic) BOOL periodic;
@property (nonatomic) BOOL enabled;
@property (nonatomic, readonly) BOOL finished;
@property (nonatomic) BOOL stopOnTerminate; 
@property (nonatomic) BOOL requiresExternalPower;
@property (nonatomic) BOOL requiresNetworkConnectivity;

+(void)load;
+(NSMutableArray *)tasks;
+(void) add:(TSBGTask*)tsTask;
+(void) remove:(TSBGTask*)tsTask;
+(TSBGTask*) get:(NSString*)identifier;

+(void)registerForTaskWithIdentifier:(NSString*)identifier;
+(BOOL)useProcessingTaskScheduler;

-(instancetype) initWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic callback:(void (^)(NSString* taskId, BOOL timeout))callback;
-(instancetype) initWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic requiresExternalPower:(BOOL)requiresExternalPower requiresNetworkConnectivity:(BOOL)requiresNetworkConnectivity callback:(void (^)(NSString* taskId, BOOL timeout))callback;

-(instancetype) initWithDictionary:(NSDictionary*)config;

-(BOOL) execute;
-(void) finish:(BOOL)success;

-(NSError*) schedule;
-(void) stop;
-(void) setTask:(BGProcessingTask*)task API_AVAILABLE(ios(13));
-(void) destroy;
-(void) save;

@end

