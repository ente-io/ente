//
//  SYMetadataCIFF.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataCIFF.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataCIFF

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(descr):                (NSString *)kCGImagePropertyCIFFDescription,
             SYStringSel(firmware):             (NSString *)kCGImagePropertyCIFFFirmware,
             SYStringSel(ownerName):            (NSString *)kCGImagePropertyCIFFOwnerName,
             SYStringSel(imageName):            (NSString *)kCGImagePropertyCIFFImageName,
             SYStringSel(imageFileName):        (NSString *)kCGImagePropertyCIFFImageFileName,
             SYStringSel(releaseMethod):        (NSString *)kCGImagePropertyCIFFReleaseMethod,
             SYStringSel(releaseTiming):        (NSString *)kCGImagePropertyCIFFReleaseTiming,
             SYStringSel(recordID):             (NSString *)kCGImagePropertyCIFFRecordID,
             SYStringSel(selfTimingTime):       (NSString *)kCGImagePropertyCIFFSelfTimingTime,
             SYStringSel(cameraSerialNumber):   (NSString *)kCGImagePropertyCIFFCameraSerialNumber,
             SYStringSel(imageSerialNumber):    (NSString *)kCGImagePropertyCIFFImageSerialNumber,
             SYStringSel(continuousDrive):      (NSString *)kCGImagePropertyCIFFContinuousDrive,
             SYStringSel(focusMode):            (NSString *)kCGImagePropertyCIFFFocusMode,
             SYStringSel(meteringMode):         (NSString *)kCGImagePropertyCIFFMeteringMode,
             SYStringSel(shootingMode):         (NSString *)kCGImagePropertyCIFFShootingMode,
             SYStringSel(lensModel):            (NSString *)kCGImagePropertyCIFFLensModel,
             SYStringSel(lensMaxMM):            (NSString *)kCGImagePropertyCIFFLensMaxMM,
             SYStringSel(lensMinMM):            (NSString *)kCGImagePropertyCIFFLensMinMM,
             SYStringSel(whiteBalanceIndex):    (NSString *)kCGImagePropertyCIFFWhiteBalanceIndex,
             SYStringSel(flashExposureComp):    (NSString *)kCGImagePropertyCIFFFlashExposureComp,
             SYStringSel(measuredEV):           (NSString *)kCGImagePropertyCIFFMeasuredEV,
             
             SYStringSel(maxAperture):          (NSString *)kSYImagePropertyCIFFMaxAperture,
             SYStringSel(minAperture):          (NSString *)kSYImagePropertyCIFFMinAperture,
             SYStringSel(uniqueModelID):        (NSString *)kSYImagePropertyCIFFUniqueModelID,
             };
}

@end
