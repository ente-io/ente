//
// Created by Caijinglong on 2019-09-06.
//

#import "PMPlugin.h"
#import "PMConvertUtils.h"
#import "PMAssetPathEntity.h"
#import "PMFilterOption.h"
#import "PMLogUtils.h"
#import "PMManager.h"
#import "PMNotificationManager.h"
#import "ResultHandler.h"
#import "PMThumbLoadOption.h"
#import "PMProgressHandler.h"
#import "PMConverter.h"

#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@implementation PMPlugin {
  BOOL ignoreCheckPermission;
  NSObject <FlutterPluginRegistrar> *privateRegistrar;
}

- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar {
  privateRegistrar = registrar;
  [self initNotificationManager:registrar];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"top.kikt/photo_manager"
                                  binaryMessenger:[registrar messenger]];
  PMManager *manager = [PMManager new];
  manager.converter = [PMConverter new];
  [self setManager:manager];
  [channel
      setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        [self onMethodCall:call result:result];
      }];
}

- (void)initNotificationManager:(NSObject <FlutterPluginRegistrar> *)registrar {
  self.notificationManager = [PMNotificationManager managerWithRegistrar:registrar];
}

- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  ResultHandler *handler = [ResultHandler handlerWithResult:result];
  PMManager *manager = self.manager;

  if ([call.method isEqualToString:@"requestPermissionExtend"]) {
    int requestAccessLevel = [call.arguments[@"iosAccessLevel"] intValue];
    [self handlePermission:manager handler:handler requestAccessLevel:requestAccessLevel];
  } else if ([call.method isEqualToString:@"presentLimited"]) {
    [self presentLimited];
  } else if ([call.method isEqualToString:@"clearFileCache"]) {
    [manager clearFileCache];
    [handler reply:@1];
  } else if ([call.method isEqualToString:@"openSetting"]) {
    [PMManager openSetting];
    [handler reply:@1];
  } else if ([call.method isEqualToString:@"ignorePermissionCheck"]) {
    ignoreCheckPermission = [call.arguments[@"ignore"] boolValue];
    [handler reply:@(ignoreCheckPermission)];
  } else if (manager.isAuth) {
    [self onAuth:call result:result];
  } else if ([call.method isEqualToString:@"log"]) {
    PMLogUtils.sharedInstance.isLog = (BOOL) call.arguments;
    [handler reply:@1];
  } else {
    if (ignoreCheckPermission) {
      [self onAuth:call result:result];
    } else {
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        BOOL auth = PHAuthorizationStatusAuthorized == status;
        [manager setAuth:auth];
        if (auth) {
          [self onAuth:call result:result];
        } else {
          [handler replyError:@"need permission"];
        }
      }];
    }
  }
}

-(void)replyPermssionResult:(ResultHandler*) handler status:(PHAuthorizationStatus)status{
    BOOL auth = PHAuthorizationStatusAuthorized == status;
    [self.manager setAuth:auth];
    [handler reply:@(status)];
}

#if TARGET_OS_IOS
#if __IPHONE_14_0

- (void) handlePermission:(PMManager *)manager handler:(ResultHandler*) handler requestAccessLevel:(int)requestAccessLevel {
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
          [self replyPermssionResult:handler status:status];
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          [self replyPermssionResult:handler status:status];
        }];
    }
}

-(UIViewController*) getCurrentViewController {
    UIViewController *ctl = UIApplication.sharedApplication.keyWindow.rootViewController;
    if(ctl){
        UIViewController *result = ctl;
        while(1){
            if(result.presentedViewController) {
                result = result.presentedViewController;
            } else {
                return result;
            }
        }
    }
    return nil;
}

-(void)presentLimited {
    if (@available(iOS 14, *)) {
        UIViewController* ctl = [self getCurrentViewController];
        if(!ctl){
            return;
        }
        [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController: ctl];
    }
}

#else

- (void) handlePermission:(PMManager *)manager handler:(ResultHandler*) handler requestAccessLevel:(int)requestAccessLevel {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      [self replyPermssionResult:handler status:status];
    }];
}

-(void)presentLimited {
}

#endif
#endif

#if TARGET_OS_OSX
- (void) handlePermission:(PMManager *)manager handler:(ResultHandler*) handler requestAccessLevel:(int)requestAccessLevel {
    if (@available(macOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
            [self replyPermssionResult:handler status:status];
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          [self replyPermssionResult:handler status:status];
        }];
    }
}

-(void)presentLimited {
}

#endif

- (void)runInBackground:(dispatch_block_t)block {
  dispatch_async(dispatch_get_global_queue(0, 0), block);
}

- (void)onAuth:(FlutterMethodCall *)call result:(FlutterResult)result {
  ResultHandler *handler = [ResultHandler handlerWithResult:result];
  PMManager *manager = self.manager;
  __block PMNotificationManager *notificationManager = self.notificationManager;

  [self runInBackground:^{
    if ([call.method isEqualToString:@"getGalleryList"]) {

      int type = [call.arguments[@"type"] intValue];
      BOOL hasAll = [call.arguments[@"hasAll"] boolValue];
      BOOL onlyAll = [call.arguments[@"onlyAll"] boolValue];
      PMFilterOptionGroup *option =
          [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
      NSArray<PMAssetPathEntity *> *array = [manager getGalleryList:type hasAll:hasAll onlyAll:onlyAll option:option];

      if (option.containsModified) {
        for (PMAssetPathEntity *path in array) {
          [manager injectModifyToDate:path];
        }
      }

      NSDictionary *dictionary = [PMConvertUtils convertPathToMap:array];
      [handler reply:dictionary];


    } else if ([call.method isEqualToString:@"getAssetWithGalleryId"]) {
      NSString *id = call.arguments[@"id"];
      int type = [call.arguments[@"type"] intValue];
      NSUInteger page = [call.arguments[@"page"] unsignedIntValue];
      NSUInteger pageCount = [call.arguments[@"pageCount"] unsignedIntValue];
      PMFilterOptionGroup *option =
          [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
      NSArray<PMAssetEntity *> *array =
          [manager getAssetEntityListWithGalleryId:id type:type page:page pageCount:pageCount filterOption:option];
      NSDictionary *dictionary =
          [PMConvertUtils convertAssetToMap:array optionGroup:option];
      [handler reply:dictionary];

    } else if ([call.method isEqualToString:@"getAssetListWithRange"]) {
      NSString *galleryId = call.arguments[@"galleryId"];
      NSUInteger type = [call.arguments[@"type"] unsignedIntegerValue];
      NSUInteger start = [call.arguments[@"start"] unsignedIntegerValue];
      NSUInteger end = [call.arguments[@"end"] unsignedIntegerValue];
      PMFilterOptionGroup *option =
          [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
      NSArray<PMAssetEntity *> *array =
          [manager getAssetEntityListWithRange:galleryId type:type start:start end:end filterOption:option];
      NSDictionary *dictionary =
          [PMConvertUtils convertAssetToMap:array optionGroup:option];
      [handler reply:dictionary];

    } else if ([call.method isEqualToString:@"getThumb"]) {
      NSString *id = call.arguments[@"id"];
      NSDictionary *dict = call.arguments[@"option"];
      PMProgressHandler *progressHandler = [self getProgressHandlerFromDict:call.arguments];
      PMThumbLoadOption *option = [PMThumbLoadOption optionDict:dict];

      [manager getThumbWithId:id option:option resultHandler:handler progressHandler:progressHandler];

    } else if ([call.method isEqualToString:@"getFullFile"]) {
      NSString *id = call.arguments[@"id"];
      BOOL isOrigin = [call.arguments[@"isOrigin"] boolValue];
      PMProgressHandler *progressHandler = [self getProgressHandlerFromDict:call.arguments];

      [manager getFullSizeFileWithId:id isOrigin:isOrigin resultHandler:handler progressHandler:progressHandler];

    } else if ([call.method isEqualToString:@"releaseMemCache"]) {
      [manager clearCache];
    } else if ([call.method isEqualToString:@"fetchPathProperties"]) {
      NSString *id = call.arguments[@"id"];
      int requestType = [call.arguments[@"type"] intValue];
      PMFilterOptionGroup *option =
          [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
      PMAssetPathEntity *pathEntity = [manager fetchPathProperties:id type:requestType filterOption:option];
      if (option.containsModified) {
        [manager injectModifyToDate:pathEntity];
      }
      if (pathEntity) {
        NSDictionary *dictionary =
            [PMConvertUtils convertPathToMap:@[pathEntity]];
        [handler reply:dictionary];
      } else {
        [handler reply:nil];
      }

    } else if ([call.method isEqualToString:@"openSetting"]) {
      [PMManager openSetting];
    } else if ([call.method isEqualToString:@"notify"]) {
      BOOL notify = [call.arguments[@"notify"] boolValue];
      if (notify) {
        [notificationManager startNotify];
      } else {
        [notificationManager stopNotify];
      }

    } else if ([call.method isEqualToString:@"isNotifying"]) {
      BOOL isNotifying = [notificationManager isNotifying];
      [handler reply:@(isNotifying)];

    } else if ([call.method isEqualToString:@"deleteWithIds"]) {
      NSArray<NSString *> *ids = call.arguments[@"ids"];
      [manager deleteWithIds:ids
                changedBlock:^(NSArray<NSString *> *array) {
                  [handler reply:array];
                }];

    } else if ([call.method isEqualToString:@"saveImage"]) {
      NSData *data = [call.arguments[@"image"] data];
      NSString *title = call.arguments[@"title"];
      NSString *desc = call.arguments[@"desc"];

      [manager saveImage:data
                   title:title
                    desc:desc
                   block:^(PMAssetEntity *asset) {
                     if (!asset) {
                       [handler reply:nil];
                       return;
                     }
                     NSDictionary *resultData =
                         [PMConvertUtils convertPMAssetToMap:asset needTitle:NO];
                     [handler reply:@{@"data": resultData}];
                   }];

    } else if ([call.method isEqualToString:@"saveImageWithPath"]) {
      NSString *path = call.arguments[@"path"];
      NSString *title = call.arguments[@"title"];
      NSString *desc = call.arguments[@"desc"];

      [manager saveImageWithPath:path
                           title:title
                            desc:desc
                           block:^(PMAssetEntity *asset) {
                             if (!asset) {
                               [handler reply:nil];
                               return;
                             }
                             NSDictionary *resultData =
                                 [PMConvertUtils convertPMAssetToMap:asset needTitle:NO];
                             [handler reply:@{@"data": resultData}];
                           }];

    } else if ([call.method isEqualToString:@"saveVideo"]) {
      NSString *videoPath = call.arguments[@"path"];
      NSString *title = call.arguments[@"title"];
      NSString *desc = call.arguments[@"desc"];

      [manager saveVideo:videoPath
                   title:title
                    desc:desc
                   block:^(PMAssetEntity *asset) {
                     if (!asset) {
                       [handler reply:nil];
                       return;
                     }
                     NSDictionary *resultData =
                         [PMConvertUtils convertPMAssetToMap:asset needTitle:NO];
                     [handler reply:@{@"data": resultData}];
                   }];

    } else if ([call.method isEqualToString:@"assetExists"]) {
      NSString *assetId = call.arguments[@"id"];
      BOOL exists = [manager existsWithId:assetId];
      [handler reply:@(exists)];
    } else if ([call.method isEqualToString:@"getTitleAsync"]) {
      NSString *assetId = call.arguments[@"id"];
      NSString *title = [manager getTitleAsyncWithAssetId:assetId];
      [handler reply:title];
    } else if ([@"getMediaUrl" isEqualToString:call.method]) {
      [manager getMediaUrl:call.arguments[@"id"] resultHandler:handler];
    } else if ([@"getPropertiesFromAssetEntity" isEqualToString:call.method]) {
      NSString *assetId = call.arguments[@"id"];
      PMAssetEntity *entity = [manager getAssetEntity:assetId];
      if (entity == nil) {
        [handler reply:nil];
        return;
      }
      NSDictionary *resultMap = [PMConvertUtils convertPMAssetToMap:entity needTitle:YES];
      [handler reply:@{@"data": resultMap}];
    } else if ([@"getSubPath" isEqualToString:call.method]) {
      NSString *galleryId = call.arguments[@"id"];
      int type = [call.arguments[@"type"] intValue];
      int albumType = [call.arguments[@"albumType"] intValue];
      NSDictionary *optionMap = call.arguments[@"option"];
      PMFilterOptionGroup *option = [PMConvertUtils convertMapToOptionContainer:optionMap];

      NSArray<PMAssetPathEntity *> *array = [manager getSubPathWithId:galleryId type:type albumType:albumType option:option];
      NSDictionary *pathData = [PMConvertUtils convertPathToMap:array];

      [handler reply:@{@"list": pathData}];
    } else if ([@"copyAsset" isEqualToString:call.method]) {
      NSString *assetId = call.arguments[@"assetId"];
      NSString *galleryId = call.arguments[@"galleryId"];
      [manager copyAssetWithId:assetId toGallery:galleryId block:^(PMAssetEntity *entity, NSString *msg) {
        if (msg) {
          NSLog(@"copy asset error, cause by : %@", msg);
          [handler reply:nil];
        } else {
          [handler reply:[PMConvertUtils convertPMAssetToMap:entity needTitle:NO]];
        }
      }];

    } else if ([@"createFolder" isEqualToString:call.method]) {
      NSString *name = call.arguments[@"name"];
      BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
      NSString *parentId = call.arguments[@"folderId"];

      if (isRoot) {
        parentId = nil;
      }

      [manager createFolderWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
        [handler reply:[self convertToResult:id errorMsg:errorMsg]];
      }];

    } else if ([@"createAlbum" isEqualToString:call.method]) {
      NSString *name = call.arguments[@"name"];
      BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
      NSString *parentId = call.arguments[@"folderId"];

      if (isRoot) {
        parentId = nil;
      }

      [manager createAlbumWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
        [handler reply:[self convertToResult:id errorMsg:errorMsg]];
      }];

    } else if ([@"removeInAlbum" isEqualToString:call.method]) {
      NSArray *assetId = call.arguments[@"assetId"];
      NSString *pathId = call.arguments[@"pathId"];

      [manager removeInAlbumWithAssetId:assetId albumId:pathId block:^(NSString *msg) {
        if (msg) {
          [handler reply:@{@"msg": msg}];
        } else {
          [handler reply:@{@"success": @YES}];
        }
      }];

    } else if ([@"deleteAlbum" isEqualToString:call.method]) {
      NSString *id = call.arguments[@"id"];
      int type = [call.arguments[@"type"] intValue];
      [manager removeCollectionWithId:id type:type block:^(NSString *msg) {
        if (msg) {
          [handler reply:@{@"errorMsg": msg}];
        } else {
          [handler reply:@{@"result": @YES}];
        }
      }];
    } else if ([@"favoriteAsset" isEqualToString:call.method]) {
      NSString *id = call.arguments[@"id"];
      BOOL favorite = [call.arguments[@"type"] boolValue];
      BOOL favoriteResult = [manager favoriteWithId:id favorite:favorite];

      [handler reply:@(favoriteResult)];
    } else if ([@"isAuth" isEqualToString:call.method]) {
      [handler reply:@YES];
    } else if ([@"requestCacheAssetsThumb" isEqualToString:call.method]) {
      NSArray *ids = call.arguments[@"ids"];
      PMThumbLoadOption *option = [PMThumbLoadOption optionDict:call.arguments[@"option"]];
      [manager requestCacheAssetsThumb:ids option:option];
      [handler reply:@YES];
    } else if ([@"cancelCacheRequests" isEqualToString:call.method]) {
      [manager cancelCacheRequests];
      [handler reply:@YES];
    } else {
      [handler notImplemented];
    }
  }];

}

- (NSDictionary *)convertToResult:(NSString *)id errorMsg:(NSString *)errorMsg {
  NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
  if (errorMsg) {
    mutableDictionary[@"errorMsg"] = errorMsg;
  }

  if (id) {
    mutableDictionary[@"id"] = id;
  }

  return mutableDictionary;
}

- (PMProgressHandler *)getProgressHandlerFromDict:(NSDictionary *)dict {
  id progressIndex = dict[@"progressHandler"];
  if (!progressIndex) {
    return nil;
  }
  int index = [progressIndex intValue];
  PMProgressHandler *handler = [PMProgressHandler new];
  [handler register:privateRegistrar channelIndex:index];

  return handler;
}

@end
