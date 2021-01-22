//
//SYMetadataEXIF.m
//SYPictureMetadataExample
//
//Created by Stan Chevallier on 12/13/12.
//Copyright (c2012 Syan. All rights reserved.
//

#import "SYMetadataEXIF.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataExif

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(exposureTime):             (NSString *)kCGImagePropertyExifExposureTime,
             SYStringSel(fNumber):                  (NSString *)kCGImagePropertyExifFNumber,
             SYStringSel(exposureProgram):          (NSString *)kCGImagePropertyExifExposureProgram,
             SYStringSel(spectralSensitivity):      (NSString *)kCGImagePropertyExifSpectralSensitivity,
             SYStringSel(isoSpeedRatings):          (NSString *)kCGImagePropertyExifISOSpeedRatings,
             SYStringSel(oecf):                     (NSString *)kCGImagePropertyExifOECF,
             SYStringSel(version):                  (NSString *)kCGImagePropertyExifVersion,
             SYStringSel(dateTimeOriginal):         (NSString *)kCGImagePropertyExifDateTimeOriginal,
             SYStringSel(dateTimeDigitized):        (NSString *)kCGImagePropertyExifDateTimeDigitized,
             SYStringSel(componentsConfiguration):  (NSString *)kCGImagePropertyExifComponentsConfiguration,
             SYStringSel(compressedBitsPerPixel):   (NSString *)kCGImagePropertyExifCompressedBitsPerPixel,
             SYStringSel(shutterSpeedValue):        (NSString *)kCGImagePropertyExifShutterSpeedValue,
             SYStringSel(apertureValue):            (NSString *)kCGImagePropertyExifApertureValue,
             SYStringSel(brightnessValue):          (NSString *)kCGImagePropertyExifBrightnessValue,
             SYStringSel(exposureBiasValue):        (NSString *)kCGImagePropertyExifExposureBiasValue,
             SYStringSel(maxApertureValue):         (NSString *)kCGImagePropertyExifMaxApertureValue,
             SYStringSel(subjectDistance):          (NSString *)kCGImagePropertyExifSubjectDistance,
             SYStringSel(meteringMode):             (NSString *)kCGImagePropertyExifMeteringMode,
             SYStringSel(lightSource):              (NSString *)kCGImagePropertyExifLightSource,
             SYStringSel(flash):                    (NSString *)kCGImagePropertyExifFlash,
             SYStringSel(focalLength):              (NSString *)kCGImagePropertyExifFocalLength,
             SYStringSel(subjectArea):              (NSString *)kCGImagePropertyExifSubjectArea,
             SYStringSel(makerNote):                (NSString *)kCGImagePropertyExifMakerNote,
             SYStringSel(userComment):              (NSString *)kCGImagePropertyExifUserComment,
             SYStringSel(subsecTime):               (NSString *)kCGImagePropertyExifSubsecTime,
             SYStringSel(subsecTimeOriginal):       (NSString *)kCGImagePropertyExifSubsecTimeOrginal,
             SYStringSel(subsecTimeDigitized):      (NSString *)kCGImagePropertyExifSubsecTimeDigitized,
             SYStringSel(flashPixVersion):          (NSString *)kCGImagePropertyExifFlashPixVersion,
             SYStringSel(colorSpace):               (NSString *)kCGImagePropertyExifColorSpace,
             SYStringSel(pixelXDimension):          (NSString *)kCGImagePropertyExifPixelXDimension,
             SYStringSel(pixelYDimension):          (NSString *)kCGImagePropertyExifPixelYDimension,
             SYStringSel(relatedSoundFile):         (NSString *)kCGImagePropertyExifRelatedSoundFile,
             SYStringSel(flashEnergy):              (NSString *)kCGImagePropertyExifFlashEnergy,
             SYStringSel(spatialFrequencyResponse): (NSString *)kCGImagePropertyExifSpatialFrequencyResponse,
             SYStringSel(focalPlaneXResolution):    (NSString *)kCGImagePropertyExifFocalPlaneXResolution,
             SYStringSel(focalPlaneYResolution):    (NSString *)kCGImagePropertyExifFocalPlaneYResolution,
             SYStringSel(focalPlaneResolutionUnit): (NSString *)kCGImagePropertyExifFocalPlaneResolutionUnit,
             SYStringSel(subjectLocation):          (NSString *)kCGImagePropertyExifSubjectLocation,
             SYStringSel(exposureIndex):            (NSString *)kCGImagePropertyExifExposureIndex,
             SYStringSel(sensingMethod):            (NSString *)kCGImagePropertyExifSensingMethod,
             SYStringSel(fileSource):               (NSString *)kCGImagePropertyExifFileSource,
             SYStringSel(sceneType):                (NSString *)kCGImagePropertyExifSceneType,
             SYStringSel(cfaPattern):               (NSString *)kCGImagePropertyExifCFAPattern,
             SYStringSel(customRendered):           (NSString *)kCGImagePropertyExifCustomRendered,
             SYStringSel(exposureMode):             (NSString *)kCGImagePropertyExifExposureMode,
             SYStringSel(whiteBalance):             (NSString *)kCGImagePropertyExifWhiteBalance,
             SYStringSel(digitalZoomRatio):         (NSString *)kCGImagePropertyExifDigitalZoomRatio,
             SYStringSel(focalLenIn35mmFilm):       (NSString *)kCGImagePropertyExifFocalLenIn35mmFilm,
             SYStringSel(sceneCaptureType):         (NSString *)kCGImagePropertyExifSceneCaptureType,
             SYStringSel(gainControl):              (NSString *)kCGImagePropertyExifGainControl,
             SYStringSel(contrast):                 (NSString *)kCGImagePropertyExifContrast,
             SYStringSel(saturation):               (NSString *)kCGImagePropertyExifSaturation,
             SYStringSel(sharpness):                (NSString *)kCGImagePropertyExifSharpness,
             SYStringSel(deviceSettingDescription): (NSString *)kCGImagePropertyExifDeviceSettingDescription,
             SYStringSel(subjectDistRange):         (NSString *)kCGImagePropertyExifSubjectDistRange,
             SYStringSel(imageUniqueID):            (NSString *)kCGImagePropertyExifImageUniqueID,
             SYStringSel(cameraOwnerName):          (NSString *)kCGImagePropertyExifCameraOwnerName,
             SYStringSel(bodySerialNumber):         (NSString *)kCGImagePropertyExifBodySerialNumber,
             SYStringSel(lensSpecification):        (NSString *)kCGImagePropertyExifLensSpecification,
             SYStringSel(lensMake):                 (NSString *)kCGImagePropertyExifLensMake,
             SYStringSel(lensModel):                (NSString *)kCGImagePropertyExifLensModel,
             SYStringSel(lensSerialNumber):         (NSString *)kCGImagePropertyExifLensSerialNumber,
             SYStringSel(gamma):                    (NSString *)kCGImagePropertyExifGamma,
             SYStringSel(sensitivityType):          (NSString *)kCGImagePropertyExifSensitivityType,
             SYStringSel(standardOutputSensitivity):(NSString *)kCGImagePropertyExifStandardOutputSensitivity,
             SYStringSel(recommendedExposureIndex): (NSString *)kCGImagePropertyExifRecommendedExposureIndex,
             SYStringSel(isoSpeed):                 (NSString *)kCGImagePropertyExifISOSpeed,
             SYStringSel(isoSpeedLatitudeyyy):      (NSString *)kCGImagePropertyExifISOSpeedLatitudeyyy,
             SYStringSel(isoSpeedLatitudezzz):      (NSString *)kCGImagePropertyExifISOSpeedLatitudezzz,
             };
}

@end
