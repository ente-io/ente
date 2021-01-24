//
//  SYMetadataMakerNikon.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataMakerNikon.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataMakerNikon

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(isoSetting):           (NSString *)kCGImagePropertyMakerNikonISOSetting,
             SYStringSel(colorMode):            (NSString *)kCGImagePropertyMakerNikonColorMode,
             SYStringSel(quality):              (NSString *)kCGImagePropertyMakerNikonQuality,
             SYStringSel(whiteBalanceMode):     (NSString *)kCGImagePropertyMakerNikonWhiteBalanceMode,
             SYStringSel(sharpenMode):          (NSString *)kCGImagePropertyMakerNikonSharpenMode,
             SYStringSel(focusMode):            (NSString *)kCGImagePropertyMakerNikonFocusMode,
             SYStringSel(flashSetting):         (NSString *)kCGImagePropertyMakerNikonFlashSetting,
             SYStringSel(isoSelection):         (NSString *)kCGImagePropertyMakerNikonISOSelection,
             SYStringSel(flashExposureComp):    (NSString *)kCGImagePropertyMakerNikonFlashExposureComp,
             SYStringSel(imageAdjustment):      (NSString *)kCGImagePropertyMakerNikonImageAdjustment,
             SYStringSel(lensAdapter):          (NSString *)kCGImagePropertyMakerNikonLensAdapter,
             SYStringSel(lensType):             (NSString *)kCGImagePropertyMakerNikonLensType,
             SYStringSel(lensInfo):             (NSString *)kCGImagePropertyMakerNikonLensInfo,
             SYStringSel(focusDistance):        (NSString *)kCGImagePropertyMakerNikonFocusDistance,
             SYStringSel(digitalZoom):          (NSString *)kCGImagePropertyMakerNikonDigitalZoom,
             SYStringSel(shootingMode):         (NSString *)kCGImagePropertyMakerNikonShootingMode,
             SYStringSel(cameraSerialNumber):   (NSString *)kCGImagePropertyMakerNikonCameraSerialNumber,
             SYStringSel(shutterCount):         (NSString *)kCGImagePropertyMakerNikonShutterCount,
             };
}

@end
