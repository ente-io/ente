//
//  SYMetadataDNG.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataDNG.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataDNG

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(version):              (NSString *)kCGImagePropertyDNGVersion,
             SYStringSel(backwardVersion):      (NSString *)kCGImagePropertyDNGBackwardVersion,
             SYStringSel(uniqueCameraModel):    (NSString *)kCGImagePropertyDNGUniqueCameraModel,
             SYStringSel(localizedCameraModel): (NSString *)kCGImagePropertyDNGLocalizedCameraModel,
             SYStringSel(cameraSerialNumber):   (NSString *)kCGImagePropertyDNGCameraSerialNumber,
             SYStringSel(lensInfo):             (NSString *)kCGImagePropertyDNGLensInfo,
             
             
             };
}

@end
