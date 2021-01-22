//
//  SYMetadataGIF.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataGIF.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataGIF

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(loopCount):            (NSString *)kCGImagePropertyGIFLoopCount,
             SYStringSel(delayTime):            (NSString *)kCGImagePropertyGIFDelayTime,
             SYStringSel(imageColorMap):        (NSString *)kCGImagePropertyGIFImageColorMap,
             SYStringSel(hasGlobalColorMap):    (NSString *)kCGImagePropertyGIFHasGlobalColorMap,
             SYStringSel(unclampedDelayTime):   (NSString *)kCGImagePropertyGIFUnclampedDelayTime,
             };
}

@end
