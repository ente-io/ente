//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import "PMImport.h"

@class PMManager;
@class PMNotificationManager;

@interface PMPlugin : NSObject
@property(nonatomic, strong) PMManager *manager;
@property(nonatomic, strong) PMNotificationManager *notificationManager;
- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@end
