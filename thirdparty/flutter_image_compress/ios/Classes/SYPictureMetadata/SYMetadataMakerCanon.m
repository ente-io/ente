//
//  SYMetadataMakerCanon.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataMakerCanon.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataMakerCanon

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(ownerName):            (NSString *)kCGImagePropertyMakerCanonOwnerName,
             SYStringSel(cameraSerialNumber):   (NSString *)kCGImagePropertyMakerCanonCameraSerialNumber,
             SYStringSel(imageSerialNumber):    (NSString *)kCGImagePropertyMakerCanonImageSerialNumber,
             SYStringSel(flashExposureComp):    (NSString *)kCGImagePropertyMakerCanonFlashExposureComp,
             SYStringSel(continuousDrive):      (NSString *)kCGImagePropertyMakerCanonContinuousDrive,
             SYStringSel(lensModel):            (NSString *)kCGImagePropertyMakerCanonLensModel,
             SYStringSel(firmware):             (NSString *)kCGImagePropertyMakerCanonFirmware,
             SYStringSel(aspectRatioInfo):      (NSString *)kCGImagePropertyMakerCanonAspectRatioInfo,
             
             // data is read by iOS but is not accessible via a publicly declared key. we use the one from CIFF
             SYStringSel(whiteBalanceIndex):    (NSString *)kCGImagePropertyCIFFWhiteBalanceIndex,
             
             SYStringSel(maxAperture):          (NSString *)kSYImagePropertyCIFFMaxAperture,
             SYStringSel(minAperture):          (NSString *)kSYImagePropertyCIFFMinAperture,
             SYStringSel(uniqueModelID):        (NSString *)kSYImagePropertyCIFFUniqueModelID,
             };
}

@end

