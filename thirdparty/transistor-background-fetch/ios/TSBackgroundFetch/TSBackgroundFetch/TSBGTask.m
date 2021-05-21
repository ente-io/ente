//
//  TSBGTask.m
//  TSBackgroundFetch
//
//  Created by Christopher Scott on 2020-01-23.
//  Copyright © 2020 Christopher Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSBGTask.h"

static NSString *const TAG = @"TSBackgroundFetch";
static NSString *const TASKS_STORAGE_KEY = @"TSBackgroundFetch:tasks";

static BOOL _hasRegisteredProcessingTaskScheduler   = NO;

static NSString *const ERROR_PROCESSING_TASK_NOT_REGISTERED = @"Background procssing task was not registered in AppDelegate didFinishLaunchingWithOptions.  See iOS Setup Guide.";
static NSString *const ERROR_PROCESSING_TASK_NOT_AVAILABLE = @"Background procssing tasks are only available with iOS 13+";

static NSMutableArray *_tasks;

@implementation TSBGTask {
    BOOL scheduled;
}

#pragma mark Class Methods

+(void)registerForTaskWithIdentifier:(NSString*)identifier API_AVAILABLE(ios(13)) {
    _hasRegisteredProcessingTaskScheduler = YES;
        
    NSLog(@"[%@ registerForTaskWithIdentifier: %@", TAG, identifier);
    
    [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:identifier usingQueue:nil launchHandler:^(BGTask* task) {
        TSBGTask *tsTask = [self get:task.identifier];
        if (!tsTask) {
            NSLog(@"[%@ registerForTaskWithIdentifier launchHandler] ERROR:  Failed to find TSBGTask in Fetch event: %@", TAG, task.identifier);
            [task setTaskCompletedWithSuccess:NO];
            return;
        }
        [tsTask setTask:(BGProcessingTask*)task];
    }];
}

+(BOOL)useProcessingTaskScheduler {
    return _hasRegisteredProcessingTaskScheduler;
}

+(void)load {
    [[self class] tasks];
}

+ (NSMutableArray*)tasks
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _tasks = [NSMutableArray new];
        // Load the set of taskIds, eg: ["foo, "bar"]
        NSArray *taskIds = [defaults objectForKey:TASKS_STORAGE_KEY];
        // Foreach taskId, load TSBGTask config from NSDefaults, eg: "TSBackgroundFetch:foo"
        for (NSString *taskId in taskIds) {
            NSString *key = [NSString stringWithFormat:@"%@:%@", TAG, taskId];
            NSDictionary *config = [defaults objectForKey:key];
            TSBGTask *tsTask = [[TSBGTask alloc] initWithDictionary:config];
            [_tasks addObject:tsTask];
        }
        NSLog(@"[%@ load]: %@", TAG, _tasks);
    });
    @synchronized (_tasks) {
        return [_tasks copy];
    }
}

+ (TSBGTask*) get:(NSString*)identifier {
    @synchronized (_tasks) {
        for (TSBGTask *tsTask in _tasks) {
            if ([tsTask.identifier isEqualToString:identifier]) {
                return tsTask;
            }
        }
    }
    return nil;
}

+ (void) add:(TSBGTask*)tsTask {
    @synchronized (_tasks) {
        [_tasks addObject:tsTask];
    }
}

+ (void) remove:(TSBGTask*)tsTask {
    @synchronized (_tasks) {
        [_tasks removeObject:tsTask];
    }
}

# pragma mark Instance Methods

-(instancetype)init {
    self = [super init];
    scheduled = NO;
    
    _enabled = NO;
    _executed = NO;
    _finished = NO;
    _requiresNetworkConnectivity = NO;
    _requiresExternalPower = NO;
    return self;
}

/// @deprecated
-(instancetype) initWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic callback:(void (^)(NSString* taskId, BOOL timeout))callback {
    return [self initWithIdentifier:identifier delay:delay periodic:periodic requiresExternalPower:NO requiresNetworkConnectivity:NO callback:callback];
}

-(instancetype) initWithIdentifier:(NSString*)identifier delay:(NSTimeInterval)delay periodic:(BOOL)periodic requiresExternalPower:(BOOL)requiresExternalPower requiresNetworkConnectivity:(BOOL)requiresNetworkConnectivity callback:(void (^)(NSString* taskId, BOOL timeout))callback {
    
    self = [self init];
    
    if (self) {
        _identifier = identifier;
        _delay = delay;
        _periodic = periodic;
        _requiresExternalPower = requiresExternalPower;
        _requiresNetworkConnectivity = requiresNetworkConnectivity;
        [TSBGTask add:self];
    }
    return self;
}

-(instancetype) initWithDictionary:(NSDictionary*)config {
    self = [self init];
    if (self) {
        _identifier = [config objectForKey:@"identifier"];
        _delay = [[config objectForKey:@"delay"] longValue];
        _periodic = [[config objectForKey:@"periodic"] boolValue];
        _enabled = [[config objectForKey:@"enabled"] boolValue];
        if ([config objectForKey:@"requiresExternalPower"]) {
            _requiresExternalPower = [[config objectForKey:@"requiresExternalPower"] boolValue];
        }
        if ([config objectForKey:@"requiresNetworkConnectivity"]) {
            _requiresNetworkConnectivity = [[config objectForKey:@"requiresNetworkConnectivity"] boolValue];
        }
    }
    return self;
}

- (NSError*) schedule {
    if (@available (iOS 13.0, *)) {
        if (![TSBGTask useProcessingTaskScheduler]) {
            return [[NSError alloc] initWithDomain:TAG code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:ERROR_PROCESSING_TASK_NOT_REGISTERED}];
        }
        
        NSLog(@"[%@ scheduleProcessingTask] %@", TAG, self);
    
        BGTaskScheduler *scheduler = [BGTaskScheduler sharedScheduler];
        
        if (scheduled) {
            [[BGTaskScheduler sharedScheduler] cancelTaskRequestWithIdentifier:_identifier];
        }
        
        BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc] initWithIdentifier:_identifier];
        // TODO Configurable.
        request.requiresExternalPower = _requiresExternalPower;
        request.requiresNetworkConnectivity = _requiresNetworkConnectivity;
        request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:_delay];
        
        NSError *error = nil;
        [scheduler submitTaskRequest:request error:&error];
        if (!error) {
            scheduled = YES;
            if (!_enabled) {
                _enabled = YES;
                [self save];
            }
        }
        return error;
    } else {
        return [[NSError alloc] initWithDomain:TAG code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey:ERROR_PROCESSING_TASK_NOT_AVAILABLE}];
    }
}

- (void) stop {
    _enabled = NO;
    scheduled = NO;
        
    [self destroy];
        
    if (@available(iOS 13.0, *)) {
        [[BGTaskScheduler sharedScheduler] cancelTaskRequestWithIdentifier:_identifier];
    }
}

-(void) setTask:(BGProcessingTask*)task {
    scheduled = NO;
    
    _task = task;
    
    task.expirationHandler = ^{
        NSLog(@"[%@ expirationHandler] WARNING: %@ '%@' expired before #finish was executed.", TAG, NSStringFromClass([self.task class]), self.identifier);
        [self onTimeout];
        // TODO Disabled with onTimeout implementation.
        //[self finish:NO];
    };

    // If no callback registered for TSTask, the app was launched in background.  The event will be handled once task is scheduled.
    if (_callback) {
        [self execute];
    }
}

- (BOOL) execute {
    if (@available(iOS 13.0, *)) {
        if ([TSBGTask useProcessingTaskScheduler] && _periodic && !scheduled) {
            [self schedule];
        }
    }
    _finished = NO;
    if (_callback) {
        _callback(_identifier, NO);
        _executed = YES;
        return YES;
    } else {
        return NO;
    }    
}

- (BOOL) onTimeout {
    if (_callback) {
        _callback(_identifier, YES);
        return YES;
    } else {
        return NO;
    }
}

-(void) finish:(BOOL)success {
    [_task setTaskCompletedWithSuccess:success];
    _finished = YES;
    _executed = NO;
    _task = nil;
    if (!_periodic) {
        [self destroy];
    }
}

-(void) save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *taskIds = [[defaults objectForKey:TASKS_STORAGE_KEY] mutableCopy];
    if (!taskIds) {
        taskIds = [NSMutableArray new];
    }
    if (![taskIds containsObject:_identifier]) {
        [taskIds addObject:_identifier];
        [defaults setObject:taskIds forKey:TASKS_STORAGE_KEY];
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", TAG, _identifier];
    NSLog(@"[TSBGTask save]: %@", self);
    [defaults setObject:[self toDictionary] forKey:key];
}

-(void) destroy {
    [TSBGTask remove:self];
            
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *taskIds = [[defaults objectForKey:TASKS_STORAGE_KEY] mutableCopy];
    if (!taskIds) {
        taskIds = [NSMutableArray new];
    }
    if ([taskIds containsObject:_identifier]) {
        [taskIds removeObject:_identifier];
        [defaults setObject:taskIds forKey:TASKS_STORAGE_KEY];
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", TAG, _identifier];
    if ([defaults objectForKey:key]) {
        [defaults removeObjectForKey:key];
    }
    NSLog(@"[TSBGTask destroy] %@", _identifier);
}

-(NSDictionary*) toDictionary {
    return @{
        @"identifier": _identifier,
        @"delay": @(_delay),
        @"periodic": @(_periodic),
        @"enabled": @(_enabled),
        @"requiresExternalPower": @(_requiresExternalPower),
        @"requiresNetworkConnectivity": @(_requiresNetworkConnectivity)
    };
}

-(NSString*) description {
    return [NSString stringWithFormat:@"<TSBGTask identifier=%@, delay=%ld, periodic=%d requiresNetworkConnectivity=%d requiresExternalPower=%d, enabled=%d>", _identifier, (long)_delay, _periodic, _requiresNetworkConnectivity, _requiresExternalPower, _enabled];
}

@end
