//
//  AssetEntity.h
//  photo_manager
//
//  Created by Caijinglong on 2018/10/19.
//

#import <Foundation/Foundation.h>
#import <Photos/PHAsset.h>

@interface AssetEntity : NSObject

@property(nonatomic,strong) PHAsset *asset;
@property(nonatomic, assign) BOOL isCloud;

@end
