//
//  SYMetadataPNG.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataPNG.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataPNG

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(gamma):                (NSString *)kCGImagePropertyPNGGamma,
             SYStringSel(interlaceType):        (NSString *)kCGImagePropertyPNGInterlaceType,
             SYStringSel(xPixelsPerMeter):      (NSString *)kCGImagePropertyPNGXPixelsPerMeter,
             SYStringSel(yPixelsPerMeter):      (NSString *)kCGImagePropertyPNGYPixelsPerMeter,
             SYStringSel(sRGBIntent):           (NSString *)kCGImagePropertyPNGsRGBIntent,
             SYStringSel(chromaticities):       (NSString *)kCGImagePropertyPNGChromaticities,
             SYStringSel(author):               (NSString *)kCGImagePropertyPNGAuthor,
             SYStringSel(copyright):            (NSString *)kCGImagePropertyPNGCopyright,
             SYStringSel(creationTime):         (NSString *)kCGImagePropertyPNGCreationTime,
             SYStringSel(descr):                (NSString *)kCGImagePropertyPNGDescription,
             SYStringSel(modificationTime):     (NSString *)kCGImagePropertyPNGModificationTime,
             SYStringSel(software):             (NSString *)kCGImagePropertyPNGSoftware,
             SYStringSel(title):                (NSString *)kCGImagePropertyPNGTitle,
             SYStringSel(loopCount):            (NSString *)kCGImagePropertyAPNGLoopCount,
             SYStringSel(delayTime):            (NSString *)kCGImagePropertyAPNGDelayTime,
             SYStringSel(unclampedDelayTime):   (NSString *)kCGImagePropertyAPNGUnclampedDelayTime,
             SYStringSel(compressionFilter):    (NSString *)kCGImagePropertyPNGCompressionFilter,
             };
}

@end
