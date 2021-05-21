//
//  TSBGAppRefreshSubscriber.m
//  TSBackgroundFetch
//
//  Created by Christopher Scott on 2020-02-07.
//  Copyright © 2020 Christopher Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSBGAppRefreshSubscriber.h"
#import "TSBackgroundFetch.h"

static NSString *const TAG = @"TSBGAppRefreshSubscriber";

static NSMutableDictionary *_subscribers;
static BOOL _hasRegisteredTaskScheduler   = NO;
    
@implementation TSBGAppRefreshSubscriber {
    
}

+(void)load {
    [[self class] subscribers];
}

+ (NSMutableDictionary*)subscribers
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _subscribers = [NSMutableDictionary new];
        // Load the set of taskIds, eg: ["foo, "bar"]
        NSArray *subscribers = [defaults objectForKey:TAG];
        // Foreach taskId, load TSBGTask config from NSDefaults, eg: "TSBackgroundFetch:foo"
        for (NSString *identifier in subscribers) {
            TSBGAppRefreshSubscriber *subscriber = [[TSBGAppRefreshSubscriber alloc] initWithIdentifier:identifier];
            [_subscribers setObject:subscriber forKey:identifier];
        }
        NSLog(@"[%@ load]: %@", TAG, _subscribers);
    });
    return _subscribers;
}

+ (TSBGAppRefreshSubscriber*) get:(NSString*)identifier {
    @synchronized (_subscribers) {
        return [_subscribers objectForKey:identifier];
    }
}

+ (void) add:(TSBGAppRefreshSubscriber*)subscriber {
    @synchronized (_subscribers) {
        [_subscribers setObject:subscriber forKey:subscriber.identifier];
    }
}

+ (void) remove:(TSBGAppRefreshSubscriber*)subscriber {
    @synchronized (_subscribers) {
        [_subscribers removeObjectForKey:subscriber.identifier];
    }
}

+(void)registerTaskScheduler{
    _hasRegisteredTaskScheduler = YES;
}

+(BOOL)useTaskScheduler {
    return _hasRegisteredTaskScheduler;
}

+(void) execute {
    NSArray *subscribers = [[self subscribers] allValues];
    for (TSBGAppRefreshSubscriber *subscriber in subscribers) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [subscriber execute];
        });
    }
}

+(BOOL) onTimeout {
    BOOL foundTimeoutHandler = NO;
    NSArray *subscribers = [[self subscribers] allValues];
    for (TSBGAppRefreshSubscriber *subscriber in subscribers) {
        foundTimeoutHandler = YES;
        if (subscriber.timeout) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [subscriber onTimeout];
            });
        } else {
            [[TSBackgroundFetch sharedInstance] finish:subscriber.identifier];
        }
    }
    return foundTimeoutHandler;
}


-(instancetype)init {
    self = [super init];
    _enabled = YES;
    _finished = NO;
    _executed = NO;
    return self;
}

-(instancetype) initWithIdentifier:(NSString*)identifier {
    self = [self init];
    if (self) {
        _identifier = identifier;
    }
    return self;
}

-(instancetype) initWithIdentifier:(NSString*)identifier callback:(void (^)(NSString* taskId))callback timeout:(void (^)(NSString* taskId))timeout {
    self = [self init];
    if (self) {
        _identifier = identifier;
        _callback = callback;
        _timeout = timeout;
        [self save];
        @synchronized (_subscribers) {
            [_subscribers setObject:self forKey:identifier];
        }
        
    }
    return self;
}

-(void) execute {
    if (_executed || !_callback) return;
    
    _executed = YES;
    _finished = NO;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.callback(self.identifier);
    });
}

-(void) onTimeout {
    if (!_timeout) {
        [self finish];
        return;
    }
    if (!_finished) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.timeout(self.identifier);
        });
    }
}

-(void) finish {
    _finished = YES;
    _executed = NO;
}

-(void) destroy {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *subscribers = [[defaults objectForKey:TAG] mutableCopy];
    
    [TSBGAppRefreshSubscriber remove:self];
    
    if (!subscribers) {
        subscribers = [NSMutableArray new];
    }
    if ([subscribers containsObject:_identifier]) {
        [subscribers removeObject:_identifier];
        [defaults setObject:subscribers forKey:TAG];
    }
}
-(void) save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *subscribers = [[defaults objectForKey:TAG] mutableCopy];
    if (!subscribers) {
        subscribers = [NSMutableArray new];
    }
    
    if ([subscribers containsObject:_identifier]) {
        return;
    }
    
    [subscribers addObject:_identifier];
    [defaults setObject:subscribers forKey:TAG];
}

-(NSString*) description {
    return [NSString stringWithFormat:@"<%@ identifier=%@, executed=%d, enabled=%d>", TAG, _identifier, _executed, _enabled];
}
@end
