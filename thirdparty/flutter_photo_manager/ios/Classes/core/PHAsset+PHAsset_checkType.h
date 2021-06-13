//
//  PHAsset+PHAsset_checkType.h
//  photo_manager
//
//  Created by Caijinglong on 2018/10/11.
//

#import <Photos/Photos.h>

@interface PHAsset (PHAsset_checkType)

-(bool) isImage;
-(bool) isVideo;

- (bool)isAudio;

-(bool) isImageOrVideo;

@end
