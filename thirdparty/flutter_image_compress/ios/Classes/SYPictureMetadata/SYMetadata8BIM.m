//
//  SYMetadata8BIM.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadata8BIM.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadata8BIM

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(layerNames):   (NSString *)kCGImageProperty8BIMLayerNames,
             SYStringSel(version):      (NSString *)kCGImageProperty8BIMVersion,
             };
}

@end

