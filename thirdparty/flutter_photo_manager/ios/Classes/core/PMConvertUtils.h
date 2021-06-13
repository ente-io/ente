//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
@class PMAssetPathEntity;
@class PMAssetEntity;
@class PMFilterOption;
@class PMFilterOptionGroup;

@interface PMConvertUtils : NSObject

+ (NSDictionary *)convertPathToMap:(NSArray<PMAssetPathEntity *> *)array;

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array
                        optionGroup:(PMFilterOptionGroup *)optionGroup;

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset
                            needTitle:(BOOL)needTitle;

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset
                            needTitle:(BOOL)needTitle;

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map;

+ (PMFilterOptionGroup *)convertMapToOptionContainer:(NSDictionary *)map;
@end
