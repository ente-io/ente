//
//  SYMetadataExifAux.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c 2012 Syan. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "SYMetadataExifAux.h"

@implementation SYMetadataExifAux

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(lensInfo):             (NSString *)kCGImagePropertyExifAuxLensInfo,
             SYStringSel(lensModel):            (NSString *)kCGImagePropertyExifAuxLensModel,
             SYStringSel(serialNumber):         (NSString *)kCGImagePropertyExifAuxSerialNumber,
             SYStringSel(lensID):               (NSString *)kCGImagePropertyExifAuxLensID,
             SYStringSel(lensSerialNumber):     (NSString *)kCGImagePropertyExifAuxLensSerialNumber,
             SYStringSel(imageNumber):          (NSString *)kCGImagePropertyExifAuxImageNumber,
             SYStringSel(flashCompensation):    (NSString *)kCGImagePropertyExifAuxFlashCompensation,
             SYStringSel(ownerName):            (NSString *)kCGImagePropertyExifAuxOwnerName,
             SYStringSel(firmware):             (NSString *)kCGImagePropertyExifAuxFirmware,
             
             // iOS reads the data but the keys are not publicly declared, we use the Nikon equivalents
             SYStringSel(focusMode):            (NSString *)kCGImagePropertyMakerNikonFocusMode,
             SYStringSel(focusDistance):        (NSString *)kCGImagePropertyMakerNikonFocusDistance,
             
             SYStringSel(afInfo):               (NSString *)kSYImagePropertyExifAuxAutoFocusInfo,
             SYStringSel(imageStabilization):   (NSString *)kSYImagePropertyExifAuxImageStabilization,
             };
}

@end
