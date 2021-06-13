//
//  PHAsset+PHAsset_getTitle.h
//  photo_manager
//
//  Created by Caijinglong on 2020/1/15.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN


@interface PHAsset (PHAsset_getTitle)

- (NSString*)title;

- (BOOL)isAdjust;

- (PHAssetResource *)getAdjustResource;

- (void)requestAdjustedData:(void (^)(NSData *_Nullable result))block;

@end

NS_ASSUME_NONNULL_END
