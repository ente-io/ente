//
//  PHAsset+PHAsset_getTitle.m
//  photo_manager
//
//  Created by Caijinglong on 2020/1/15.
//

#import "PHAsset+PHAsset_getTitle.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PMLogUtils.h"

@implementation PHAsset (PHAsset_getTitle)

- (NSString *)title {
    PMLogUtils *logger = [PMLogUtils sharedInstance];
    [logger info:@"get title start"];
    @try {
        NSString *result = [self valueForKey:@"filename"];
        [logger info:@"get title from kvo"];
        return result;
    } @catch (NSException *exception) {
        [logger info: @"get title from PHAssetResource"];
        NSArray *array = [PHAssetResource assetResourcesForAsset:self];
        for (PHAssetResource *resource in array) {
          if ([self isImage] && resource.type == PHAssetResourceTypePhoto) {
            return resource.originalFilename;
          } else if ([self isVideo] && resource.type == PHAssetResourceTypeVideo) {
            return resource.originalFilename;
          }
        }

        PHAssetResource *firstRes = array.firstObject;
        if (firstRes) {
          return firstRes.originalFilename;
        }

        return @"";
    }
}

- (BOOL)isAdjust {
  NSArray<PHAssetResource *> *resources =
      [PHAssetResource assetResourcesForAsset:self];
  if (resources.count == 1) {
    return NO;
  }

  if (self.mediaType == PHAssetMediaTypeImage) {
    return [self imageIsAdjust:resources];
  } else if (self.mediaType == PHAssetMediaTypeVideo) {
    return [self videoIsAdjust:resources];
  }

  return NO;
}

- (BOOL)imageIsAdjust:(NSArray<PHAssetResource *> *)resources {
  int count = 0;
  for (PHAssetResource *res in resources) {
    if (res.type == PHAssetResourceTypePhoto ||
        res.type == PHAssetResourceTypeFullSizePhoto) {
      count++;
    }
  }

  return count > 1;
}

- (BOOL)videoIsAdjust:(NSArray<PHAssetResource *> *)resources {
  int count = 0;
  for (PHAssetResource *res in resources) {
    if (res.type == PHAssetResourceTypeVideo ||
        res.type == PHAssetResourceTypeFullSizeVideo) {
      count++;
    }
  }

  return count > 1;
}

- (PHAssetResource *)getAdjustResource {
  NSArray<PHAssetResource *> *resources =
      [PHAssetResource assetResourcesForAsset:self];
  if (resources.count == 0) {
    return nil;
  }

  if (resources.count == 1) {
    return resources[0];
  }

  if (![self isAdjust]) {
    for (PHAssetResource *res in resources) {
      if (self.mediaType == PHAssetMediaTypeImage ||
          res.type == PHAssetResourceTypeFullSizePhoto ||
          res.type == PHAssetResourceTypePhoto) {
        return res;
      }

      if (self.mediaType == PHAssetMediaTypeVideo ||
          res.type == PHAssetResourceTypeFullSizeVideo ||
          res.type == PHAssetResourceTypeVideo) {
        return res;
      }
    }

    return nil;
  }

  for (PHAssetResource *res in resources) {
    if (self.mediaType == PHAssetMediaTypeImage ||
        res.type == PHAssetResourceTypeFullSizePhoto) {
      return res;
    }

    if (self.mediaType == PHAssetMediaTypeVideo ||
        res.type == PHAssetResourceTypeFullSizeVideo) {
      return res;
    }
  }

  return nil;
}

- (void)requestAdjustedData:(void (^)(NSData *_Nullable))block {
  PHAssetResource *res = [self getAdjustResource];

  PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;
  PHAssetResourceRequestOptions *opt = [PHAssetResourceRequestOptions new];

  __block double pro = 0;

  opt.networkAccessAllowed = YES;
  opt.progressHandler = ^(double progress) {
    pro = progress;
  };

  [manager requestDataForAssetResource:res
                               options:opt
                   dataReceivedHandler:^(NSData *_Nonnull data) {
                     if (pro != 1) {
                       return;
                     }
                     block(data);
                   }
                     completionHandler:^(NSError *_Nullable error){

                     }];
}

@end
