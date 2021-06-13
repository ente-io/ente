//
// Created by Caijinglong on 2019-09-09.
//

#import "PMNotificationManager.h"
#import "PMConvertUtils.h"
#import "core/PMLogUtils.h"

@interface PMNotificationManager () <PHPhotoLibraryChangeObserver>
@end

@implementation PMNotificationManager {
  FlutterMethodChannel *channel;
  BOOL _notifying;
  PHFetchResult<PHAsset *> *result;
}

- (instancetype)initWithRegistrar:
        (NSObject <FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    self.registrar = registrar;
    channel = [FlutterMethodChannel
            methodChannelWithName:@"top.kikt/photo_manager/notify"
                  binaryMessenger:[registrar messenger]];
    _notifying = NO;
  }

  return self;
}

+ (instancetype)managerWithRegistrar:
        (NSObject <FlutterPluginRegistrar> *)registrar {
  return [[self alloc] initWithRegistrar:registrar];
}

- (void)startNotify {
  PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
  [library registerChangeObserver:self];
  _notifying = YES;
  [self refreshFetchResult];
}

- (void)stopNotify {
  PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
  [library unregisterChangeObserver:self];
  _notifying = NO;
}

#pragma "photo library notify"

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
  if (!result) {
    return;
  }

  PHFetchResultChangeDetails *details = [changeInstance changeDetailsForFetchResult:result];

  NSDictionary *detailResult = [self convertChangeDetailsToNotifyDetail:details];

  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"on change result = %@", detailResult]];
  [self refreshFetchResult];

  [channel invokeMethod:@"change" arguments:detailResult];
}

- (void)refreshFetchResult {
  result = [self getLastAssets];
}

- (NSDictionary *)convertChangeDetailsToNotifyDetail:(PHFetchResultChangeDetails *)details {
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  NSArray<PHObject *> *changedObjects = details.changedObjects;
  NSArray<PHObject *> *insertedObjects = details.insertedObjects;
  NSArray<PHObject *> *removedObjects = details.removedObjects;

  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"changed = %@", changedObjects]];
  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"inserted = %@", insertedObjects]];
  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"removed = %@", removedObjects]];

  [self addToResult:dictionary key:@"update" objects:changedObjects];
  [self addToResult:dictionary key:@"create" objects:insertedObjects];
  [self addToResult:dictionary key:@"delete" objects:removedObjects];

//  return @{@"platform": @"iOS", result: dictionary};
  return dictionary;
}

- (void)addToResult:(NSMutableDictionary *)dictionary key:(NSString *)key objects:(NSArray<PHObject *> *)changedObjects {
  NSMutableArray *items = [NSMutableArray new];

  for (PHObject *object in  changedObjects) {
    if ([object isMemberOfClass:PHAsset.class]) {
      PHAsset *asset = (PHAsset *) object;
      NSMutableDictionary *itemDict = [NSMutableDictionary new];
      PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsContainingAsset:asset withType:PHAssetCollectionTypeAlbum options:nil];
      itemDict[@"id"] = object.localIdentifier;
      NSMutableArray *collectionArray = [NSMutableArray new];
      for (PHAssetCollection *collection in collections) {
        NSDictionary *collectionDict = @{@"id": collection.localIdentifier, @"title": collection.localizedTitle};
        [collectionArray addObject:collectionDict];
      }
      [items addObject:itemDict];
    }
  }

  dictionary[key] = items;
}

- (PHFetchResult<PHAsset *> *)getLastAssets {
  if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
    return [PHAsset fetchAssetsWithOptions:nil];
  }
  return nil;
}

- (BOOL)isNotifying {
  return _notifying;
}
@end
