//
// Created by Caijinglong on 2019-09-06.
//

#import "PMManager.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PHAsset+PHAsset_getTitle.h"
#import "PMAssetPathEntity.h"
#import "PMCacheContainer.h"
#import "PMFilterOption.h"
#import "PMLogUtils.h"
#import "PMRequestTypeUtils.h"
#import "NSString+PM_COMMON.h"
#import "PMFolderUtils.h"
#import "MD5Utils.h"
#import "PMThumbLoadOption.h"
#import "PMImageUtil.h"

@implementation PMManager {
  BOOL __isAuth;
  PMCacheContainer *cacheContainer;

  PHCachingImageManager *__cachingManager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    __isAuth = NO;
    cacheContainer = [PMCacheContainer new];
  }

  return self;
}

- (BOOL)isAuth {
  return __isAuth;
}

- (void)setAuth:(BOOL)auth {
  __isAuth = auth;
}

- (PHCachingImageManager *)cachingManager {
    if (__cachingManager == nil) {
        __cachingManager = [PHCachingImageManager new];
    }
    
    return __cachingManager;
}

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type hasAll:(BOOL)hasAll onlyAll:(BOOL)onlyAll option:(PMFilterOptionGroup *)option {
  NSMutableArray<PMAssetPathEntity *> *array = [NSMutableArray new];
  PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:option];

  PHFetchOptions *fetchCollectionOptions = [PHFetchOptions new];


  if (onlyAll) {
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
        fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                              subtype:PHAssetCollectionSubtypeAlbumRegular
                              options:fetchCollectionOptions];

    if (result && result.count) {
      for (PHAssetCollection *collection in result) {
        if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
          PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];
          PMAssetPathEntity *pathEntity = [PMAssetPathEntity entityWithId:collection.localIdentifier name:collection.localizedTitle assetCount:assetResult.count];
          pathEntity.isAll = YES;
          [array addObject:pathEntity];
          break;
        }
      }
    }

    return array;
  }

  PHFetchResult<PHAssetCollection *> *smartAlbumResult = [PHAssetCollection
      fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                            subtype:PHAssetCollectionSubtypeAlbumRegular
                            options:fetchCollectionOptions];

  [self logCollections:smartAlbumResult option:assetOptions];

  [self injectAssetPathIntoArray:array
                          result:smartAlbumResult
                         options:assetOptions
                          hasAll:hasAll
              containsEmptyAlbum:option.containsEmptyAlbum
  ];

  PHFetchResult<PHCollection *> *topLevelResult = [PHAssetCollection
      fetchTopLevelUserCollectionsWithOptions:fetchCollectionOptions];

  [self logCollections:topLevelResult option:assetOptions];

  [self injectAssetPathIntoArray:array
                          result:topLevelResult
                         options:assetOptions
                          hasAll:hasAll
              containsEmptyAlbum:option.containsEmptyAlbum
  ];

  return array;
}

- (void)logCollections:(PHFetchResult *)collections option:(PHFetchOptions *)option {
  if(!PMLogUtils.sharedInstance.isLog){
      return;
  }
  for (PHCollection *phCollection in collections) {
    if ([phCollection isMemberOfClass:[PHAssetCollection class]]) {
      PHAssetCollection *collection = (PHAssetCollection *) phCollection;
      PHFetchResult<PHAsset *> *result = [PHAsset fetchKeyAssetsInAssetCollection:collection options:option];
      NSLog(@"collection name = %@, count = %ld", collection.localizedTitle, result.count);
    } else {
      NSLog(@"collection name = %@", phCollection.localizedTitle);
    }
  }
}

- (BOOL)existsWithId:(NSString *)assetId {
  PHFetchResult<PHAsset *> *result =
      [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId]
                                       options:[PHFetchOptions new]];
  if (!result) {
    return NO;
  }
  return result.count >= 1;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCDFAInspection"

- (void)injectAssetPathIntoArray:(NSMutableArray<PMAssetPathEntity *> *)array
                          result:(PHFetchResult *)result
                         options:(PHFetchOptions *)options
                          hasAll:(BOOL)hasAll
              containsEmptyAlbum:(BOOL)containsEmptyAlbum {
  for (id collection in result) {
    if (![collection isMemberOfClass:[PHAssetCollection class]]) {
      continue;
    }

    PHAssetCollection *assetCollection = (PHAssetCollection *) collection;

    if (assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded
        || assetCollection.assetCollectionSubtype == 1000000201) {// Recently Deleted
      continue;
    }


    PHFetchResult<PHAsset *> *fetchResult =
        [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];

    PMAssetPathEntity *entity =
        [PMAssetPathEntity entityWithId:assetCollection.localIdentifier
                                   name:assetCollection.localizedTitle
                             assetCount:(int) fetchResult.count];

    entity.isAll = assetCollection.assetCollectionSubtype ==
        PHAssetCollectionSubtypeSmartAlbumUserLibrary;

    if (!hasAll && entity.isAll) {
      continue;
    }

    if (entity.assetCount && entity.assetCount > 0) {
      [array addObject:entity];
    } else if (containsEmptyAlbum && assetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
      [array addObject:entity];
    }
  }
}

#pragma clang diagnostic pop

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page pageCount:(NSUInteger)pageCount filterOption:(PMFilterOptionGroup *)filterOption {
  NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

  PHFetchOptions *options = [PHFetchOptions new];

  PHFetchResult<PHAssetCollection *> *fetchResult =
      [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                           options:options];
  if (fetchResult && fetchResult.count == 0) {
    return result;
  }

  PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:filterOption];

  PHAssetCollection *collection = fetchResult.firstObject;

  PHFetchResult<PHAsset *> *assetArray =
      [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

  if (assetArray.count == 0) {
    return result;
  }

  NSUInteger startIndex = page * pageCount;
  NSUInteger endIndex = startIndex + pageCount - 1;

  NSUInteger count = assetArray.count;
  if (endIndex >= count) {
    endIndex = count - 1;
  }

  BOOL imageNeedTitle = filterOption.imageOption.needTitle;
  BOOL videoNeedTitle = filterOption.videoOption.needTitle;

  for (NSUInteger i = startIndex; i <= endIndex; i++) {
    PHAsset *asset = assetArray[i];
    BOOL needTitle = NO;
    if ([asset isVideo]) {
      needTitle = videoNeedTitle;
    } else if ([asset isImage]) {
      needTitle = imageNeedTitle;
    }
    PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset needTitle:needTitle];
    [result addObject:entity];
    [cacheContainer putAssetEntity:entity];
  }

  return result;
}

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id type:(NSUInteger)type start:(NSUInteger)start end:(NSUInteger)end filterOption:(PMFilterOptionGroup *)filterOption {
  NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

  PHFetchOptions *options = [PHFetchOptions new];

  PHFetchResult<PHAssetCollection *> *fetchResult =
      [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                           options:options];
  if (fetchResult && fetchResult.count == 0) {
    return result;
  }

  PHFetchOptions *assetOptions = [self getAssetOptions:(int) type filterOption:filterOption];

  PHAssetCollection *collection = fetchResult.firstObject;
  PHFetchResult<PHAsset *> *assetArray =
      [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

  if (assetArray.count == 0) {
    return result;
  }

  NSUInteger startIndex = start;
  NSUInteger endIndex = end - 1;

  NSUInteger count = assetArray.count;
  if (endIndex >= count) {
    endIndex = count - 1;
  }

  for (NSUInteger i = startIndex; i <= endIndex; i++) {
    BOOL needTitle;

    PHAsset *asset = assetArray[i];

    if ([asset isVideo]) {
      needTitle = filterOption.videoOption.needTitle;
    } else if ([asset isImage]) {
      needTitle = filterOption.imageOption.needTitle;
    } else {
      needTitle = NO;
    }

    PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset needTitle:needTitle];
    [result addObject:entity];
    [cacheContainer putAssetEntity:entity];
  }

  return result;
}

- (PMAssetEntity *)convertPHAssetToAssetEntity:(PHAsset *)asset
                                     needTitle:(BOOL)needTitle {
  // type:
  // 0: all , 1: image, 2:video

  int type = 0;
  if (asset.isImage) {
    type = 1;
  } else if (asset.isVideo) {
    type = 2;
  }

  NSDate *date = asset.creationDate;
  long createDt = (long) date.timeIntervalSince1970;

  NSDate *modifiedDate = asset.modificationDate;
  long modifiedTimeStamp = (long) modifiedDate.timeIntervalSince1970;

  PMAssetEntity *entity = [PMAssetEntity entityWithId:asset.localIdentifier
                                             createDt:createDt
                                                width:asset.pixelWidth
                                               height:asset.pixelHeight
                                             duration:(long) asset.duration
                                                 type:type];
  entity.phAsset = asset;
  entity.modifiedDt = modifiedTimeStamp;
  entity.lat = asset.location.coordinate.latitude;
  entity.lng = asset.location.coordinate.longitude;
  entity.title = needTitle ? [asset title] : @"";
  entity.favorite = asset.isFavorite;

  return entity;
}

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId {
  PMAssetEntity *entity = [cacheContainer getAssetEntity:assetId];
  if (entity) {
    return entity;
  }
  PHFetchResult<PHAsset *> *result =
      [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil];
  if (result == nil || result.count == 0) {
    return nil;
  }

  PHAsset *asset = result[0];
  entity = [self convertPHAssetToAssetEntity:asset needTitle:NO];
  [cacheContainer putAssetEntity:entity];
  return entity;
}

- (void)clearCache {
  [cacheContainer clearCache];
}

- (void)getThumbWithId:(NSString *)id1 option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  PMAssetEntity *entity = [self getAssetEntity:id1];
  if (entity && entity.phAsset) {
    PHAsset *asset = entity.phAsset;
    [self fetchThumb:asset option:option resultHandler:handler progressHandler:progressHandler];
  } else {
    [handler replyError:@"asset is not found"];
  }
}

- (void)fetchThumb:(PHAsset *)asset option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  PHImageManager *manager = PHImageManager.defaultManager;
  PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
  requestOptions.deliveryMode = option.deliveryMode;
  requestOptions.resizeMode = option.resizeMode;

  [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];

  [requestOptions setNetworkAccessAllowed:YES];
  [requestOptions setProgressHandler:^(double progress, NSError *error, BOOL *stop,
      NSDictionary *info) {
    if (progress == 1.0) {
      [self fetchThumb:asset option:option resultHandler:handler progressHandler:nil];
    }

    if (error) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
      [progressHandler deinit];
      return;
    }
    if (progress != 1) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
    }
  }];
  int width = option.width;
  int height = option.height;

  [manager requestImageForAsset:asset
                     targetSize:CGSizeMake(width, height)
                    contentMode:option.contentMode
                        options:requestOptions
                  resultHandler:^(PMImage *result, NSDictionary *info) {
                    BOOL downloadFinished = [PMManager isDownloadFinish:info];

                    if (!downloadFinished) {
                      return;
                    }

                    if ([handler isReplied]) {
                      return;
                    }
                    NSData *imageData = [PMImageUtil convertToData:result formatType:option.format quality:option.quality];
                    if (imageData) {
                      id data = [self.converter convertData:imageData];
                      [handler reply:data];
                    } else {
                      [handler reply: nil];
                    }
      
                    [self notifySuccess:progressHandler];
                    
                  }];

}

- (void)getFullSizeFileWithId:(NSString *)id isOrigin:(BOOL)isOrigin resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  PMAssetEntity *entity = [self getAssetEntity:id];
  if (entity && entity.phAsset) {
    PHAsset *asset = entity.phAsset;
    if (asset.isVideo) {
      if (isOrigin) {
        [self fetchOriginVideoFile:asset handler:handler progressHandler:progressHandler];
      } else {
        [self fetchFullSizeVideo:asset handler:handler progressHandler:progressHandler];
      }
      return;
    } else {
      if (isOrigin) {
        [self fetchOriginImageFile:asset resultHandler:handler progressHandler:progressHandler];
      } else {
        [self fetchFullSizeImageFile:asset resultHandler:handler progressHandler:progressHandler];
      }
    }
  } else {
    [handler replyError:@"asset is not found"];
  }
}

- (void)fetchOriginVideoFile:(PHAsset *)asset handler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  NSArray<PHAssetResource *> *resources =
      [PHAssetResource assetResourcesForAsset:asset];
  // find asset
  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"The asset has %lu resources.", (unsigned long) resources.count] ];
  PHAssetResource *dstResource;
  if (resources.lastObject && resources.lastObject.type == PHAssetResourceTypeVideo) {
    dstResource = resources.lastObject;
  } else {
    for (PHAssetResource *resource in resources) {
      if (resource.type == PHAssetResourceTypeVideo) {
        dstResource = resource;
        break;
      }
    }
  }
  if (!dstResource) {
    [handler reply:nil];
    return;
  }

  PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;

  NSString *path = [self makeAssetOutputPath:asset isOrigin:YES];
  NSURL *fileUrl = [NSURL fileURLWithPath:path];

  [PMFileHelper deleteFile:path];

  PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
  [options setNetworkAccessAllowed:YES];

  [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
  [options setProgressHandler:^(double progress) {
    if (progress != 1) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
    }
  }];

  [manager writeDataForAssetResource:dstResource
                              toFile:fileUrl
                             options:options
                   completionHandler:^(NSError *_Nullable error) {
                     if (error) {
                       NSLog(@"error = %@", error);
                       [handler reply:nil];
                     } else {
                       [handler reply:path];
                       [self notifySuccess:progressHandler];
                     }
                   }];
}

- (void)fetchFullSizeVideo:(PHAsset *)asset handler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  NSString *homePath = NSTemporaryDirectory();
  NSFileManager *manager = NSFileManager.defaultManager;

  NSMutableString *path = [NSMutableString stringWithString:homePath];

  NSString *filename = [asset valueForKey:[NSString stringWithFormat:@"filename"]];

  NSString *dirPath = [NSString stringWithFormat:@"%@/%@", homePath, @".video"];
  [manager createDirectoryAtPath:dirPath
     withIntermediateDirectories:true
                      attributes:@{}
                           error:nil];

  [path appendFormat:@"%@/%@", @".video", filename];
  PHVideoRequestOptions *options = [PHVideoRequestOptions new];
  if ([manager fileExistsAtPath:path]) {
    [[PMLogUtils sharedInstance]
        info:[NSString stringWithFormat:@"read cache from %@", path]];
    [handler reply:path];
    return;
  }


  [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
  [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
      NSDictionary *info) {
    if (progress == 1.0) {
      [self fetchFullSizeVideo:asset handler:handler progressHandler:nil];
    }

    if (error) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
      [progressHandler deinit];
      return;
    }
    if (progress != 1) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
    }
  }];

  [options setNetworkAccessAllowed:YES];

  [[PHImageManager defaultManager]
      requestAVAssetForVideo:asset
                     options:options
               resultHandler:^(AVAsset *_Nullable asset,
                   AVAudioMix *_Nullable audioMix,
                   NSDictionary *_Nullable info) {
                 BOOL downloadFinish = [PMManager isDownloadFinish:info];

                 if (!downloadFinish) {
                   return;
                 }

                 NSString *preset = AVAssetExportPresetHighestQuality;
                 AVAssetExportSession *exportSession =
                     [AVAssetExportSession exportSessionWithAsset:asset
                                                       presetName:preset];
                 if (exportSession) {
                   exportSession.outputFileType = AVFileTypeMPEG4;
                   exportSession.outputURL = [NSURL fileURLWithPath:path];
                   [exportSession exportAsynchronouslyWithCompletionHandler:^{
                     [handler reply:path];
                   }];

                   [self notifySuccess:progressHandler];
                 } else {
                   [handler reply:nil];
                 }
               }];
}

- (NSString *)makeAssetOutputPath:(PHAsset *)asset isOrigin:(Boolean)isOrigin {
  NSString *homePath = NSTemporaryDirectory();
  NSString *cachePath = asset.isVideo ? @".video" : @".image";
  NSString *dirPath = [NSString stringWithFormat:@"%@%@", homePath, cachePath];
  [NSFileManager.defaultManager createDirectoryAtPath:dirPath
                          withIntermediateDirectories:true
                                           attributes:@{}
                                                error:nil];

  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"cache path = %@", dirPath]];

//  NSString *title = [asset title];
  NSMutableString *path = [NSMutableString stringWithString:dirPath];
  NSString *filename = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  NSString *extName = [asset title];
  [path appendFormat:@"/%@%@.%@", filename, isOrigin ? @"_origin" : @"", extName];
  return path;
}

- (void)fetchFullSizeImageFile:(PHAsset *)asset resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  PHImageManager *manager = PHImageManager.defaultManager;
  PHImageRequestOptions *options = [PHImageRequestOptions new];
  options.synchronous = YES;
  options.version = PHImageRequestOptionsVersionCurrent;


  [options setNetworkAccessAllowed:YES];
  [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
  [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
      NSDictionary *info) {
    if (progress == 1.0) {
      [self fetchFullSizeImageFile:asset resultHandler:handler progressHandler:nil];
    }

    if (error) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
      [progressHandler deinit];
      return;
    }
    if (progress != 1) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
    }
  }];

  [manager requestImageForAsset:asset
                     targetSize:PHImageManagerMaximumSize
                    contentMode:PHImageContentModeDefault
                        options:options
                  resultHandler:^(PMImage *_Nullable image,
                      NSDictionary *_Nullable info) {

                    BOOL downloadFinished = [PMManager isDownloadFinish:info];
                    if (!downloadFinished) {
                      return;
                    }

                    if ([handler isReplied]) {
                      return;
                    }

                    NSData *data = [PMImageUtil convertToData:image formatType:PMThumbFormatTypeJPEG quality:1.0];
                
                    if (data) {
                      NSString *path = [self writeFullFileWithAssetId:asset imageData: data];
                      [handler reply:path];
                    } else {
                      [handler reply:nil];
                    }

                    [self notifySuccess:progressHandler];
                  }];
}

- (NSString *)writeFullFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData {

  NSString *homePath = NSTemporaryDirectory();
  NSFileManager *manager = NSFileManager.defaultManager;

  NSMutableString *path = [NSMutableString stringWithString:homePath];
  [path appendString:@"flutter-images"];

  NSError *error;
  [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{} error:&error];

  [path appendString:@"/"];
  [path appendString:[MD5Utils getmd5WithString:asset.localIdentifier]];

  [path appendString:@"_exif"];

  [path appendString:@".jpg"];

//  if ([manager fileExistsAtPath:path]) {
//    return path;
//  }

  [manager createFileAtPath:path contents:imageData attributes:@{}];
  return path;
}

- (BOOL)isImage:(PHAssetResource *)resource {
  return resource.type == PHAssetResourceTypePhoto || resource.type == PHAssetResourceTypeFullSizePhoto;
}

- (void)fetchOriginImageFile:(PHAsset *)asset resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
  PHAssetResource *imageResource = [asset getAdjustResource];

  if (!imageResource) {
    [handler reply:nil];
    return;
  }

  PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;

  NSString *path = [self makeAssetOutputPath:asset isOrigin:YES];
  NSURL *fileUrl = [NSURL fileURLWithPath:path];

  [PMFileHelper deleteFile:path];

  PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
  [options setNetworkAccessAllowed:YES];


  [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];

  [options setProgressHandler:^(double progress) {
    if (progress != 1) {
      [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
    }
  }];

  [manager writeDataForAssetResource:imageResource
                              toFile:fileUrl
                             options:options
                   completionHandler:^(NSError *_Nullable error) {
                     if (error) {
                       NSLog(@"error = %@", error);
                       [handler reply:nil];
                     } else {
                       [handler reply:path];
                       [self notifySuccess:progressHandler];
                     }
                   }];
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
  return ![info[PHImageCancelledKey] boolValue] &&      // No cancel.
      !info[PHImageErrorKey] &&                      // Error.
      ![info[PHImageResultIsDegradedKey] boolValue]; // thumbnail
}

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type filterOption:(PMFilterOptionGroup *)filterOption {
  PHFetchOptions *collectionFetchOptions = [PHFetchOptions new];
  PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
      fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                        options:collectionFetchOptions];

  if (result == nil || result.count == 0) {
    return nil;
  }
  PHAssetCollection *collection = result[0];
  PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:filterOption];
  PHFetchResult<PHAsset *> *fetchResult =
      [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

  return [PMAssetPathEntity entityWithId:id
                                    name:collection.localizedTitle
                              assetCount:(int) fetchResult.count];
}

- (PHFetchOptions *)getAssetOptions:(int)type filterOption:(PMFilterOptionGroup *)optionGroup {
  PHFetchOptions *options = [PHFetchOptions new];
  options.sortDescriptors = [optionGroup sortCond];

  NSMutableString *cond = [NSMutableString new];
  NSMutableArray *args = [NSMutableArray new];

  BOOL containsImage = [PMRequestTypeUtils containsImage:type];
  BOOL containsVideo = [PMRequestTypeUtils containsVideo:type];
  BOOL containsAudio = [PMRequestTypeUtils containsAudio:type];

  if (containsImage) {
    [cond appendString:@"("];

    PMFilterOption *imageOption = optionGroup.imageOption;

    NSString *sizeCond = [imageOption sizeCond];
    NSArray *sizeArgs = [imageOption sizeArgs];

    [cond appendString:@"mediaType == %d"];
    [args addObject:@(PHAssetMediaTypeImage)];

    if (!imageOption.sizeConstraint.ignoreSize) {
      [cond appendString:@" AND "];
      [cond appendString:sizeCond];
      [args addObjectsFromArray:sizeArgs];
    }

    [cond appendString:@")"];
  }

  if (containsVideo) {
    if (![cond isEmpty]) {
      [cond appendString:@" OR "];
    }

    [cond appendString:@" ( "];

    PMFilterOption *videoOption = optionGroup.videoOption;

    [cond appendString:@"mediaType == %d"];
    [args addObject:@(PHAssetMediaTypeVideo)];

    NSString *durationCond = [videoOption durationCond];
    NSArray *durationArgs = [videoOption durationArgs];
    [cond appendString:@" AND "];
    [cond appendString:durationCond];
    [args addObjectsFromArray:durationArgs];

    [cond appendString:@" ) "];
  }

  if (containsAudio) {
    if (![cond isEmpty]) {
      [cond appendString:@" OR "];
    }

    [cond appendString:@" ( "];

    PMFilterOption *videoOption = optionGroup.audioOption;

    [cond appendString:@"mediaType == %d"];
    [args addObject:@(PHAssetMediaTypeAudio)];

    NSString *durationCond = [videoOption durationCond];
    NSArray *durationArgs = [videoOption durationArgs];
    [cond appendString:@" AND "];
    [cond appendString:durationCond];
    [args addObjectsFromArray:durationArgs];

    [PMLogUtils.sharedInstance info: [NSString stringWithFormat: @"duration = %.2f ~ %.2f", [durationArgs[0] floatValue], [durationArgs[1] floatValue]]];

    [cond appendString:@" ) "];
  }

  [cond insertString:@"(" atIndex:0];
  [cond appendString:@")"];

  PMDateOption *dateOption = optionGroup.dateOption;
  if (!dateOption.ignore) {
    [cond appendString:[dateOption dateCond:@"creationDate"]];
    [args addObjectsFromArray:[dateOption dateArgs]];
  }

  PMDateOption *updateOption = optionGroup.updateOption;
  if (!updateOption.ignore) {
    [cond appendString:[updateOption dateCond:@"modificationDate"]];
    [args addObjectsFromArray:[updateOption dateArgs]];
  }

  options.predicate = [NSPredicate predicateWithFormat:cond argumentArray:args];

  return options;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

+ (void)openSetting {
//  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//  if ([[UIApplication sharedApplication] canOpenURL:url]) {
//    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
//      [[UIApplication sharedApplication] openURL:url
//                                         options:@{}
//                               completionHandler:^(BOOL success) {
//                               }];
//    } else {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//      [[UIApplication sharedApplication] openURL:url];
//#pragma clang diagnostic pop
//    }
//
//  }
}

#pragma clang diagnostic pop

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block {
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        PHFetchResult<PHAsset *> *result =
            [PHAsset fetchAssetsWithLocalIdentifiers:ids
                                             options:[PHFetchOptions new]];
        [PHAssetChangeRequest deleteAssets:result];
      }
   completionHandler:^(BOOL success, NSError *error) {
     if (success) {
       block(ids);
     } else {
       block(@[]);
     }
   }];
}

- (void)saveImage:(NSData *)data
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block {
  __block NSString *assetId = nil;

  [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save image with data, length: %ld, title:%@, desc: %@", data.length, title, desc]];

  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        PHAssetCreationRequest *request =
            [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options =
            [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:data
                             options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
      }
   completionHandler:^(BOOL success, NSError *error) {
     if (success) {
       [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
       block([self getAssetEntity:assetId]);
     } else {
       NSLog(@"create fail");
       block(nil);
     }
   }];
}

- (void)saveImageWithPath:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(void (^)(PMAssetEntity *))block {

  [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save image with path: %@ title:%@, desc: %@", path, title, desc]];

  __block NSString *assetId = nil;
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        PHAssetCreationRequest *request =
            [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options =
            [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        NSData *data = [NSData dataWithContentsOfFile:path];
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:data
                             options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
      }
   completionHandler:^(BOOL success, NSError *error) {
     if (success) {
       [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
       block([self getAssetEntity:assetId]);
     } else {
       NSLog(@"create fail");
       block(nil);
     }
   }];
}

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block {
  [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save video with path: %@, title: %@, desc %@", path, title, desc]];
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  __block NSString *assetId = nil;
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
//              PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
//              [options setOriginalFilename:title];

//              PHAssetCreationRequest *request = [PHAssetCreationRequest
//                      creationRequestForAssetFromVideoAtFileURL:fileURL];
//              PHAssetResourceCreationOptions *options =
//                      [PHAssetResourceCreationOptions new];
//              [options setOriginalFilename:title];
//              [request addResourceWithType:PHAssetResourceTypeVideo
//                                   fileURL:fileURL
//                                   options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
      }
   completionHandler:^(BOOL success, NSError *error) {
     if (success) {
       [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
       block([self getAssetEntity:assetId]);
     } else {
       NSLog(@"create fail, error: %@", error);
       block(nil);
     }
   }];
}

- (NSString *)getTitleAsyncWithAssetId:(NSString *)assetId {
  PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
  if (asset) {
    return [asset title];
  }
  return @"";
}

- (void)getMediaUrl:(NSString *)assetId resultHandler:(NSObject <PMResultHandler> *)handler {
  PHAsset *phAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
  if (phAsset.isVideo) {
    [PHCachingImageManager.defaultManager requestAVAssetForVideo:phAsset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
      if ([asset isKindOfClass:[AVURLAsset class]]) {
        NSURL *url = ((AVURLAsset *) asset).URL;
        [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"The asset asset URL = %@", url]];
        [handler reply:url.absoluteString];
      } else {
        [handler replyError:@"cannot get videoUrl"];
      }
    }];
  }
}

- (NSArray<PMAssetPathEntity *> *)getSubPathWithId:(NSString *)id type:(int)type albumType:(int)albumType option:(PMFilterOptionGroup *)option {
  PHFetchOptions *options = [self getAssetOptions:type filterOption:option];

  if ([PMFolderUtils isRecentCollection:id]) {
    NSArray<PHCollectionList *> *array = [PMFolderUtils getRootFolderWithOptions:nil];
    return [self convertPHCollectionToPMAssetPathArray:array option:options];
  }

  if (albumType == PM_TYPE_ALBUM) {
    return @[];
  }

  PHCollectionList *list;

  PHFetchResult<PHCollectionList *> *collectionList = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
  if (collectionList && collectionList.count > 0) {
    list = collectionList.firstObject;
  }

  if (!list) {
    return @[];
  }

  NSArray<PHCollection *> *phCollectionArray = [PMFolderUtils getSubCollectionWithCollection:list options:options];
  return [self convertPHCollectionToPMAssetPathArray:phCollectionArray option:options];
}

- (NSArray<PMAssetPathEntity *> *)convertPHCollectionToPMAssetPathArray:(NSArray<PHCollection *> *)phArray
                                                                 option:(PHFetchOptions *)option {
  NSMutableArray<PMAssetPathEntity *> *result = [NSMutableArray new];

  for (PHCollection *collection in phArray) {
    [result addObject:[self convertPHCollectionToPMPath:collection option:option]];
  }

  return result;
}

- (PMAssetPathEntity *)convertPHCollectionToPMPath:(PHCollection *)phCollection option:(PHFetchOptions *)option {
  PMAssetPathEntity *pathEntity = [PMAssetPathEntity new];

  pathEntity.id = phCollection.localIdentifier;
  pathEntity.isAll = NO;
  pathEntity.name = phCollection.localizedTitle;
  if ([phCollection isMemberOfClass:PHAssetCollection.class]) {
    PHAssetCollection *collection = (PHAssetCollection *) phCollection;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
    pathEntity.assetCount = fetchResult.count;
    pathEntity.type = PM_TYPE_ALBUM;
  } else {
    pathEntity.assetCount = 0;
    pathEntity.type = PM_TYPE_FOLDER;
  }

  return pathEntity;
}

- (PHAssetCollection *)getCollectionWithId:(NSString *)galleryId {
  PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[galleryId] options:nil];

  if (fetchResult && fetchResult.count > 0) {
    return fetchResult.firstObject;
  }
  return nil;
}

- (void)copyAssetWithId:(NSString *)id toGallery:(NSString *)gallery block:(void (^)(PMAssetEntity *entity, NSString *msg))block {
  PMAssetEntity *assetEntity = [self getAssetEntity:id];

  if (!assetEntity) {
    NSString *msg = [NSString stringWithFormat:@"not found asset : %@", id];
    block(nil, msg);
    return;
  }

  __block PHAssetCollection *collection = [self getCollectionWithId:gallery];

  if (!collection) {
    NSString *msg = [NSString stringWithFormat:@"not found collection with gallery id : %@", gallery];
    block(nil, msg);
    return;
  }

  if (![collection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
    block(nil, @"The collection can't add from user. The [collection canPerformEditOperation:PHCollectionEditOperationAddContent] return NO!");
    return;
  }

  __block PHFetchResult<PHAsset *> *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:nil];
  NSError *error;

  [PHPhotoLibrary.sharedPhotoLibrary
      performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request addAssets:asset];
//              [request insertAssets:asset atIndexes:[NSIndexSet indexSetWithIndex:0]];

      } error:&error];

  if (error) {
    NSString *msg = [NSString stringWithFormat:@"Can't copy, error : %@ ", error];
    block(nil, msg);
    return;
  }

  block(assetEntity, nil);
}

- (void)createFolderWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block {
  __block NSString *targetId;
  NSError *error;
  if (id) { // create in folder
    PHFetchResult<PHCollectionList *> *result = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
    if (result && result.count > 0) {
      PHCollectionList *parent = result.firstObject;

      [PHPhotoLibrary.sharedPhotoLibrary
          performChangesAndWait:^{
            PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest creationRequestForCollectionListWithTitle:name];
            targetId = request.placeholderForCreatedCollectionList.localIdentifier;
          } error:&error];

      if (error) {
        NSLog(@"createFolderWithName 1: error : %@", error);
      }

      [PHPhotoLibrary.sharedPhotoLibrary
          performChangesAndWait:^{
            PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest changeRequestForCollectionList:parent];
            PHFetchResult<PHCollectionList *> *fetchResult = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[targetId] options:nil];
            [request addChildCollections:fetchResult];
          } error:&error];


      if (error) {
        NSLog(@"createFolderWithName 2: error : %@", error);
      }


      block(targetId, error.localizedDescription);

    } else {
      block(nil, [NSString stringWithFormat:@"Cannot find folder : %@", id]);
      return;
    }
  } else { // create in top
    [PHPhotoLibrary.sharedPhotoLibrary
        performChangesAndWait:^{
          PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest creationRequestForCollectionListWithTitle:name];
          targetId = request.placeholderForCreatedCollectionList.localIdentifier;
        } error:&error];

    if (error) {
      NSLog(@"createFolderWithName 3: error : %@", error);
    }
    block(targetId, error.localizedDescription);
  }

}

- (void)createAlbumWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block {
  __block NSString *targetId;
  NSError *error;
  if (id) { // create in folder
    PHFetchResult<PHCollectionList *> *result = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
    if (result && result.count > 0) {
      PHCollectionList *parent = result.firstObject;

      [PHPhotoLibrary.sharedPhotoLibrary
          performChangesAndWait:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
            targetId = request.placeholderForCreatedAssetCollection.localIdentifier;
          } error:&error];

      if (error) {
        NSLog(@"createAlbumWithName 1: error : %@", error);
      }

      [PHPhotoLibrary.sharedPhotoLibrary
          performChangesAndWait:^{
            PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest changeRequestForCollectionList:parent];
            PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[targetId] options:nil];
            [request addChildCollections:fetchResult];
          } error:&error];

      if (error) {
        NSLog(@"createAlbumWithName 2: error : %@", error);
      }

      block(targetId, error.localizedDescription);

    } else {
      block(nil, [NSString stringWithFormat:@"Cannot find folder : %@", id]);
      return;
    }
  } else { // create in top
    [PHPhotoLibrary.sharedPhotoLibrary
        performChangesAndWait:^{
          PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
          targetId = request.placeholderForCreatedAssetCollection.localIdentifier;
        } error:&error];

    if (error) {
      NSLog(@"createAlbumWithName 3: error : %@", error);
    }
    block(targetId, error.localizedDescription);
  }
}

- (void)removeInAlbumWithAssetId:(NSArray *)id albumId:(NSString *)albumId block:(void (^)(NSString *))block {
  PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:nil];
  PHAssetCollection *collection;
  if (result && result.count > 0) {
    collection = result.firstObject;
  } else {
    block(@"Can't found the collection.");
    return;
  }

  if (![collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]) {
    block(@"The collection cannot remove asset by user.");
    return;
  }

  PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:id options:nil];
  NSError *error;
  [PHPhotoLibrary.sharedPhotoLibrary
      performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request removeAssets:assetResult];
      } error:&error];
  if (error) {
    block([NSString stringWithFormat:@"Remove error: %@", error]);
    return;
  }

  block(nil);
}

- (id)getFirstObjFromFetchResult:(PHFetchResult<id> *)fetchResult {
  if (fetchResult && fetchResult.count > 0) {
    return fetchResult.firstObject;
  }
  return nil;
}

- (void)removeCollectionWithId:(NSString *)id type:(int)type block:(void (^)(NSString *))block {
  if (type == 1) {
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:nil];
    PHAssetCollection *collection = [self getFirstObjFromFetchResult:fetchResult];
    if (!collection) {
      block(@"Cannot found asset collection.");
      return;
    }
    if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
      block(@"The asset collection can be delete.");
      return;
    }
    NSError *error;
    [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
      [PHAssetCollectionChangeRequest deleteAssetCollections:@[collection]];
    }                                                  error:&error];

    if (error) {
      block([NSString stringWithFormat:@"Remove error: %@", error]);
      return;
    }

    block(nil);

  } else if (type == 2) {
    PHFetchResult<PHCollectionList *> *fetchResult = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
    PHCollectionList *collection = [self getFirstObjFromFetchResult:fetchResult];
    if (!collection) {
      block(@"Cannot found collection list.");
      return;
    }
    if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
      block(@"The collection list can be delete.");
      return;
    }
    NSError *error;
    [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
      [PHCollectionListChangeRequest deleteCollectionLists:@[collection]];
    }                                                  error:&error];

    if (error) {
      block([NSString stringWithFormat:@"Remove error: %@", error]);
      return;
    }

    block(nil);
  } else {
    block(@"Not support the type");
  }
}

- (BOOL)favoriteWithId:(NSString *)id favorite:(BOOL)favorite {
  PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:nil];
  PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];

  if (!asset) {
    NSLog(@"Cannot find found: %@", id);
    return NO;
  }

  NSError *error;

  [PHPhotoLibrary.sharedPhotoLibrary
      performChangesAndWait:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
        request.favorite = favorite;
      } error:&error];

  if (error) {
    NSLog(@"favorite error: %@", error);
    return NO;
  }

  return YES;
}

- (NSString *)getCachePath:(NSString *)type {
  NSString *homePath = NSTemporaryDirectory();
  NSString *cachePath = type;
  NSString *dirPath = [NSString stringWithFormat:@"%@%@", homePath, cachePath];
  return dirPath;
}

- (void)clearFileCache {
  NSString *videoPath = [self getCachePath:@".video"];
  NSString *imagePath = [self getCachePath:@".image"];

  NSFileManager *fm = NSFileManager.defaultManager;

  NSError *err;

  [fm removeItemAtPath:imagePath error:&err];
  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"remove cache file %@, error: %@", imagePath, err]];
  [fm removeItemAtPath:videoPath error:&err];
  [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"remove cache file %@, error: %@", videoPath, err]];
}

#pragma mark cache thumb

- (void)requestCacheAssetsThumb:(NSArray *)identifiers option:(PMThumbLoadOption *)option {
  PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:nil];
  NSMutableArray *array = [NSMutableArray new];

  for (id asset in fetchResult) {
    [array addObject:asset];
  }

  PHImageRequestOptions *options = [PHImageRequestOptions new];
  options.resizeMode = options.resizeMode;
  options.deliveryMode = option.deliveryMode;

  [self.cachingManager startCachingImagesForAssets:array targetSize:[option makeSize] contentMode:option.contentMode options:options];
}

- (void)cancelCacheRequests {
  [self.cachingManager stopCachingImagesForAllAssets];
}

- (void)notifyProgress:(NSObject <PMProgressHandlerProtocol> *)handler progress:(double)progress state:(PMProgressState)state {
  if (!handler) {
    return;
  }

  [handler notify:progress state:state];
}

- (void)notifySuccess:(NSObject <PMProgressHandlerProtocol> *)handler {
  [self notifyProgress:handler progress:1 state:PMProgressStateSuccess];
  [handler deinit];
}


#pragma mark inject modify date

- (void)injectModifyToDate:(PMAssetPathEntity *)path {
  NSString *pathId = path.id;
  PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[pathId] options:nil];
  if (fetchResult.count > 0) {
    PHAssetCollection *collection = fetchResult.firstObject;

    PHFetchOptions *options = [PHFetchOptions new];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO];
    options.sortDescriptors = @[sortDescriptor];

    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    PHAsset *asset = assets.firstObject;
    path.modifiedDate = (long) asset.modificationDate.timeIntervalSince1970;
  }
}

@end
