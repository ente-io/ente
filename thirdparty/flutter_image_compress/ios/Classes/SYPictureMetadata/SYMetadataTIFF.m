//
//  SYMetadataTIFF.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataTIFF.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataTIFF

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(compression):              (NSString *)kCGImagePropertyTIFFCompression,
             SYStringSel(photometricInterpretation):(NSString *)kCGImagePropertyTIFFPhotometricInterpretation,
             SYStringSel(documentName):             (NSString *)kCGImagePropertyTIFFDocumentName,
             SYStringSel(imageDescription):         (NSString *)kCGImagePropertyTIFFImageDescription,
             SYStringSel(make):                     (NSString *)kCGImagePropertyTIFFMake,
             SYStringSel(model):                    (NSString *)kCGImagePropertyTIFFModel,
             SYStringSel(orientation):              (NSString *)kCGImagePropertyTIFFOrientation,
             SYStringSel(xResolution):              (NSString *)kCGImagePropertyTIFFXResolution,
             SYStringSel(yResolution):              (NSString *)kCGImagePropertyTIFFYResolution,
             SYStringSel(resolutionUnit):           (NSString *)kCGImagePropertyTIFFResolutionUnit,
             SYStringSel(software):                 (NSString *)kCGImagePropertyTIFFSoftware,
             SYStringSel(transferFunction):         (NSString *)kCGImagePropertyTIFFTransferFunction,
             SYStringSel(dateTime):                 (NSString *)kCGImagePropertyTIFFDateTime,
             SYStringSel(artist):                   (NSString *)kCGImagePropertyTIFFArtist,
             SYStringSel(hostComputer):             (NSString *)kCGImagePropertyTIFFHostComputer,
             SYStringSel(copyright):                (NSString *)kCGImagePropertyTIFFCopyright,
             SYStringSel(whitePoint):               (NSString *)kCGImagePropertyTIFFWhitePoint,
             SYStringSel(primaryChromaticities):    (NSString *)kCGImagePropertyTIFFPrimaryChromaticities,
             
             SYStringSel(tileWidth):                (NSString *)kCGImagePropertyTIFFTileWidth,
             SYStringSel(tileLength):               (NSString *)kCGImagePropertyTIFFTileLength,
             };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:SYStringSel(photometricInterpretation)])
        return [MTLValueTransformer sy_nonZeroIntegerValueTransformer];
    
    return [super JSONTransformerForKey:key];
}

@end
