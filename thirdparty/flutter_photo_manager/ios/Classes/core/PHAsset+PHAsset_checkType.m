//
//  PHAsset+PHAsset_checkType.m
//  photo_manager
//
//  Created by Caijinglong on 2018/10/11.
//

#import "PHAsset+PHAsset_checkType.h"

@implementation PHAsset (PHAsset_checkType)

-(bool)isImage{
    return [self mediaType] == PHAssetMediaTypeImage;
}

-(bool)isVideo{
    return [self mediaType] == PHAssetMediaTypeVideo;
}

-(bool)isAudio{
    return [self mediaType] == PHAssetMediaTypeAudio;
}

-(bool)isImageOrVideo{
    return [self isVideo] || [self isImage];
}

@end
