//
//  SYMetadataGPS.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataGPS.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataGPS

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(version):          (NSString *)kCGImagePropertyGPSVersion,
             SYStringSel(latitudeRef):      (NSString *)kCGImagePropertyGPSLatitudeRef,
             SYStringSel(latitude):         (NSString *)kCGImagePropertyGPSLatitude,
             SYStringSel(longitudeRef):     (NSString *)kCGImagePropertyGPSLongitudeRef,
             SYStringSel(longitude):        (NSString *)kCGImagePropertyGPSLongitude,
             SYStringSel(altitudeRef):      (NSString *)kCGImagePropertyGPSAltitudeRef,
             SYStringSel(altitude):         (NSString *)kCGImagePropertyGPSAltitude,
             SYStringSel(timeStamp):        (NSString *)kCGImagePropertyGPSTimeStamp,
             SYStringSel(satellites):       (NSString *)kCGImagePropertyGPSSatellites,
             SYStringSel(status):           (NSString *)kCGImagePropertyGPSStatus,
             SYStringSel(measureMode):      (NSString *)kCGImagePropertyGPSMeasureMode,
             SYStringSel(dop):              (NSString *)kCGImagePropertyGPSDOP,
             SYStringSel(speedRef):         (NSString *)kCGImagePropertyGPSSpeedRef,
             SYStringSel(speed):            (NSString *)kCGImagePropertyGPSSpeed,
             SYStringSel(trackRef):         (NSString *)kCGImagePropertyGPSTrackRef,
             SYStringSel(track):            (NSString *)kCGImagePropertyGPSTrack,
             SYStringSel(imgDirectionRef):  (NSString *)kCGImagePropertyGPSImgDirectionRef,
             SYStringSel(imgDirection):     (NSString *)kCGImagePropertyGPSImgDirection,
             SYStringSel(mapDatum):         (NSString *)kCGImagePropertyGPSMapDatum,
             SYStringSel(destLatitudeRef):  (NSString *)kCGImagePropertyGPSDestLatitudeRef,
             SYStringSel(destLatitude):     (NSString *)kCGImagePropertyGPSDestLatitude,
             SYStringSel(destLongitudeRef): (NSString *)kCGImagePropertyGPSDestLongitudeRef,
             SYStringSel(destLongitude):    (NSString *)kCGImagePropertyGPSDestLongitude,
             SYStringSel(destBearingRef):   (NSString *)kCGImagePropertyGPSDestBearingRef,
             SYStringSel(destBearing):      (NSString *)kCGImagePropertyGPSDestBearing,
             SYStringSel(destDistanceRef):  (NSString *)kCGImagePropertyGPSDestDistanceRef,
             SYStringSel(destDistance):     (NSString *)kCGImagePropertyGPSDestDistance,
             SYStringSel(processingMethod): (NSString *)kCGImagePropertyGPSProcessingMethod,
             SYStringSel(areaInformation):  (NSString *)kCGImagePropertyGPSAreaInformation,
             SYStringSel(dateStamp):        (NSString *)kCGImagePropertyGPSDateStamp,
             SYStringSel(differental):      (NSString *)kCGImagePropertyGPSDifferental,
             SYStringSel(hPositioningError):(NSString *)kCGImagePropertyGPSHPositioningError,
             };
}

@end
