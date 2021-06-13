//
// Created by Caijinglong on 2019-09-06.
//

#import "PMConvertUtils.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PHAsset+PHAsset_getTitle.h"
#import "PMAssetPathEntity.h"
#import "PMFilterOption.h"

@implementation PMConvertUtils {
}

+ (NSDictionary *)convertPathToMap:(NSArray<PMAssetPathEntity *> *)array {
  NSMutableArray *data = [NSMutableArray new];

  for (PMAssetPathEntity *entity in array) {
    NSDictionary *item = @{
        @"id": entity.id,
        @"name": entity.name,
        @"length": @(entity.assetCount),
        @"isAll": @(entity.isAll),
        @"albumType": @(entity.type),
    };

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params addEntriesFromDictionary:item];

    if (entity.modifiedDate != 0) {
      params[@"modified"] = @(entity.modifiedDate);
    }

    [data addObject:params];
  }

  return @{@"data": data};
}

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array
                        optionGroup:(PMFilterOptionGroup *)optionGroup {
  NSMutableArray *data = [NSMutableArray new];

  BOOL videoShowTitle = optionGroup.videoOption.needTitle;
  BOOL imageShowTitle = optionGroup.imageOption.needTitle;

  for (PMAssetEntity *asset in array) {

    NSDictionary *item;

    if ([asset.phAsset isImage]) {
      item = [PMConvertUtils convertPMAssetToMap:asset needTitle:imageShowTitle];
    } else if ([asset.phAsset isVideo]) {
      item = [PMConvertUtils convertPMAssetToMap:asset needTitle:videoShowTitle];
    } else {
      continue;
    }
    [data addObject:item];
  }

  return @{@"data": data};
}

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset
                            needTitle:(BOOL)needTitle {
  long createDt = (int) asset.creationDate.timeIntervalSince1970;
  long modifiedDt = (int) asset.modificationDate.timeIntervalSince1970;

  int typeInt = 0;

  if (asset.isVideo) {
    typeInt = 2;
  } else if (asset.isImage) {
    typeInt = 1;
  } else if (asset.isAudio) {
    typeInt = 3;
  }

  return @{
          @"id": asset.localIdentifier,
          @"createDt": @(createDt),
          @"width": @(asset.pixelWidth),
          @"height": @(asset.pixelHeight),
          @"favorite": @(asset.favorite),
          @"duration": @((long) asset.duration),
          @"type": @(typeInt),
          @"modifiedDt": @(modifiedDt),
          @"lng": @(asset.location.coordinate.longitude),
          @"lat": @(asset.location.coordinate.latitude),
          @"title": needTitle ? [asset title] : @"",
  };
}

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset
                            needTitle:(BOOL)needTitle {
  return @{
          @"id": asset.id,
          @"createDt": @(asset.createDt),
          @"width": @(asset.width),
          @"height": @(asset.height),
          @"duration": @(asset.duration),
          @"favorite": @(asset.favorite),
          @"type": @(asset.type),
          @"modifiedDt": @(asset.modifiedDt),
          @"lng": @(asset.lng),
          @"lat": @(asset.lat),
          @"title": needTitle ? asset.title : @"",
  };
}

+ (PMFilterOptionGroup *)convertMapToOptionContainer:(NSDictionary *)map {
  PMFilterOptionGroup *container = [PMFilterOptionGroup alloc];
  NSDictionary *image = map[@"image"];
  NSDictionary *video = map[@"video"];
  NSDictionary *audio = map[@"audio"];

  container.imageOption = [self convertMapToPMFilterOption:image];
  container.videoOption = [self convertMapToPMFilterOption:video];
  container.audioOption = [self convertMapToPMFilterOption:audio];
  container.dateOption = [self convertMapToPMDateOption:map[@"createDate"]];
  container.updateOption = [self convertMapToPMDateOption:map[@"updateDate"]];
  container.containsEmptyAlbum = [map[@"containsEmptyAlbum"] boolValue];
  container.containsModified = [map[@"containsPathModified"] boolValue];

  NSArray *sortArray = map[@"orders"];
  [container injectSortArray: sortArray];

  return container;
}

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map {
  PMFilterOption *option = [PMFilterOption new];
  option.needTitle = [map[@"title"] boolValue];

  NSDictionary *sizeMap = map[@"size"];
  NSDictionary *durationMap = map[@"duration"];

  PMSizeConstraint sizeConstraint;
  sizeConstraint.minWidth = [sizeMap[@"minWidth"] unsignedIntValue];
  sizeConstraint.maxWidth = [sizeMap[@"maxWidth"] unsignedIntValue];
  sizeConstraint.minHeight = [sizeMap[@"minHeight"] unsignedIntValue];
  sizeConstraint.maxHeight = [sizeMap[@"maxHeight"] unsignedIntValue];
  sizeConstraint.ignoreSize = [sizeMap[@"ignoreSize"] boolValue];
  option.sizeConstraint = sizeConstraint;

  PMDurationConstraint durationConstraint;
  durationConstraint.minDuration =
          [PMConvertUtils convertNSNumberToSecond:durationMap[@"min"]];
  durationConstraint.maxDuration =
          [PMConvertUtils convertNSNumberToSecond:durationMap[@"max"]];
  option.durationConstraint = durationConstraint;


  return option;
}

+ (PMDateOption *)convertMapToPMDateOption:(NSDictionary *)map {
  PMDateOption *option = [PMDateOption new];

  long min = [map[@"min"] longValue];
  long max = [map[@"max"] longValue];
  BOOL ignore = [map[@"ignore"] boolValue];

  option.min = [NSDate dateWithTimeIntervalSince1970:(min / 1000.0)];
  option.max = [NSDate dateWithTimeIntervalSince1970:(max / 1000.0)];
  option.ignore = ignore;

  return option;
}

+ (double)convertNSNumberToSecond:(NSNumber *)number {
  unsigned int i = number.unsignedIntValue;
  return (double) i / 1000.0;
}

@end
