//
//  SYMetadataExif.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYMetadataBase.h"

typedef enum {
    SYPictureExifExposureProgram_NotDefined = 0,
    SYPictureExifExposureProgram_Manual = 1,
    SYPictureExifExposureProgram_NormalProgram = 2,
    SYPictureExifExposureProgram_AperturePriority = 3,
    SYPictureExifExposureProgram_ShutterPriority = 4,
    SYPictureExifExposureProgram_CreativeProgram = 5, // (biased toward depth of field)
    SYPictureExifExposureProgram_ActionProgram = 6, // (biased toward fast shutter speed)
    SYPictureExifExposureProgram_PortraitMode = 7, // (for closeup photos with the background out of focus)
    SYPictureExifExposureProgram_LandscapeMode = 8 // (for landscape photos with the background in focus)
} SYPictureExifExposureProgram;

typedef enum {
    SYPictureExifMeteringMode_Unknown = 0,
    SYPictureExifMeteringMode_Average = 1,
    SYPictureExifMeteringMode_CenterWeightedAverage = 2,
    SYPictureExifMeteringMode_Spot = 3,
    SYPictureExifMeteringMode_MultiSpot = 4,
    SYPictureExifMeteringMode_Pattern = 5,
    SYPictureExifMeteringMode_Partial = 6,
    SYPictureExifMeteringMode_Other = 255
} SYPictureExifMeteringMode;

typedef enum {
    SYPictureExifLightSource_Unknown = 0,
    SYPictureExifLightSource_Daylight = 1,
    SYPictureExifLightSource_Fluorescent = 2,
    SYPictureExifLightSource_TungstenIncandescentLight = 3,
    SYPictureExifLightSource_Flash = 4,
    SYPictureExifLightSource_FineWeather = 9,
    SYPictureExifLightSource_CloudyWeather = 10,
    SYPictureExifLightSource_Shade = 11,
    SYPictureExifLightSource_DaylightFluorescent = 12, // (D 5700 - 7100K)
    SYPictureExifLightSource_DayWhiteFluorescent = 13, // (N 4600 - 5400K)
    SYPictureExifLightSource_CoolWhiteFluorescent = 14, // (W 3900 - 4500K)
    SYPictureExifLightSource_WhiteFluorescent = 15, // (WW 3200 - 3700K)
    SYPictureExifLightSource_StandardLightA = 17,
    SYPictureExifLightSource_StandardLightB = 18,
    SYPictureExifLightSource_StandardLightC = 19,
    SYPictureExifLightSource_D55 = 20,
    SYPictureExifLightSource_D65 = 21,
    SYPictureExifLightSource_D75 = 22,
    SYPictureExifLightSource_D50 = 23,
    SYPictureExifLightSource_ISOStudioTungsten = 24,
    SYPictureExifLightSource_OtherLightSource = 255
} SYPictureExifLightSource;

typedef enum {
    SYPictureExifFocalPlaneResolutionUnit_NoAbsoluteUnitOfMeasurement = 1,
    SYPictureExifFocalPlaneResolutionUnit_Inch = 2,
    SYPictureExifFocalPlaneResolutionUnit_Centimeter = 3
} SYPictureExifFocalPlaneResolutionUnit;

typedef enum {
    SYPictureExifSensingMethod_NotDefined = 1,
    SYPictureExifSensingMethod_OneChipColorAreaSensor = 2,
    SYPictureExifSensingMethod_TwoChipColorAreaSensor = 3,
    SYPictureExifSensingMethod_ThreeChipColorAreaSensor = 4,
    SYPictureExifSensingMethod_ColorSequentialAreaSensor = 5,
    SYPictureExifSensingMethod_TrilinearSensor = 7,
    SYPictureExifSensingMethod_ColorSequentialLinearSensor = 8
} SYPictureExifSensingMethod;

typedef enum {
    SYPictureExifCustomRendered_NormalProcess = 0,
    SYPictureExifCustomRendered_CustomProcess = 1
} SYPictureExifCustomRendered;

typedef enum {
    SYPictureExifExposureMode_AutoExposure = 0,
    SYPictureExifExposureMode_ManualExposure = 1,
    SYPictureExifExposureMode_AutoBracket = 2
} SYPictureExifExposureMode;

typedef enum {
    SYPictureExifWhiteBalance_Auto = 0,
    SYPictureExifWhiteBalance_Manual = 1
} SYPictureExifWhiteBalance;

typedef enum {
    SYPictureExifSceneCaptureType_Standard = 0,
    SYPictureExifSceneCaptureType_Landscape = 1,
    SYPictureExifSceneCaptureType_Portrait = 2,
    SYPictureExifSceneCaptureType_NightScene = 3
} SYPictureExifSceneCaptureType;

typedef enum {
    SYPictureExifGainControl_None = 0,
    SYPictureExifGainControl_LowGainUp = 1,
    SYPictureExifGainControl_HighGainUp = 2,
    SYPictureExifGainControl_LowGainDown = 3,
    SYPictureExifGainControl_HighGainDown = 4
} SYPictureExifGainControl;

typedef enum {
    SYPictureExifContrast_Normal = 0,
    SYPictureExifContrast_Soft = 1,
    SYPictureExifContrast_Hard = 2
} SYPictureExifContrast;

typedef enum {
    SYPictureExifSaturation_Normal = 0,
    SYPictureExifSaturation_LowSaturation = 1,
    SYPictureExifSaturation_HighSaturation = 2
} SYPictureExifSaturation;

typedef enum {
    SYPictureExifSharpness_Normal = 0,
    SYPictureExifSharpness_Soft = 1,
    SYPictureExifSharpness_Hard = 2
} SYPictureExifSharpness;

typedef enum {
    SYPictureExifSubjectDistanceRange_Unknown = 0,
    SYPictureExifSubjectDistanceRange_Macro = 1,
    SYPictureExifSubjectDistanceRange_CloseView = 2,
    SYPictureExifSubjectDistanceRange_DistantView = 3
} SYPictureExifSubjectDistanceRange;

typedef enum : NSUInteger {
    SYMetadataExifSensitivityType_Unknown                                                          = 0,
    SYMetadataExifSensitivityType_StandardOutputSensitivity                                        = 1,
    SYMetadataExifSensitivityType_RecommendedExposureIndex                                         = 2,
    SYMetadataExifSensitivityType_ISOSpeed                                                         = 3,
    SYMetadataExifSensitivityType_StandardOutputSensitivityAndRecommendedExposureIndex             = 4,
    SYMetadataExifSensitivityType_StandardOutputSensitivityAndISOSpeed                             = 5,
    SYMetadataExifSensitivityType_RecommendedExposureIndexAndISOSpeed                              = 6,
    SYMetadataExifSensitivityType_StandardOutputSensitivityAndRecommendedExposureIndexAndISOSpeed  = 7,
} SYMetadataExifSensitivityType;

typedef enum : NSUInteger {
    SYMetadataExifFlash_FlashDidNotFire                                                        = 0x0000,
    SYMetadataExifFlash_FlashFired                                                             = 0x0001,
    SYMetadataExifFlash_StrobeReturnLightNotDetected                                           = 0x0005,
    SYMetadataExifFlash_StrobeReturnLightDetected                                              = 0x0007,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashMode                                          = 0x0009,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashModeReturnLightNotDetected                    = 0x000D,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashModeReturnLightDetected                       = 0x000F,
    SYMetadataExifFlash_FlashDidNotFireCompulsoryDlashMode                                     = 0x0010,
    SYMetadataExifFlash_FlashDidNotFireAutoMode                                                = 0x0018,
    SYMetadataExifFlash_FlashFiredAutoMode                                                     = 0x0019,
    SYMetadataExifFlash_FlashFiredAutoModeReturnLightNotDetected                               = 0x001D,
    SYMetadataExifFlash_FlashFiredAutoModeReturnLightDetected                                  = 0x001F,
    SYMetadataExifFlash_NoFlashFunction                                                        = 0x0020,
    SYMetadataExifFlash_FlashFiredRedEyeReductionMode                                          = 0x0041,
    SYMetadataExifFlash_FlashFiredRedEyeReductionModeReturnLightNotDetected                    = 0x0045,
    SYMetadataExifFlash_FlashFiredRedEyeReductionModeReturnLightDetected                       = 0x0047,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashModeRedEyeReductionMode                       = 0x0049,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashModeRedEyeReductionModeReturnLightNotDetected = 0x004D,
    SYMetadataExifFlash_FlashFiredCompulsoryFlashModeRedEyeReductionModeReturnLightDetected    = 0x004F,
    SYMetadataExifFlash_FlashFiredAutoModeRedEyeReductionMode                                  = 0x0059,
    SYMetadataExifFlash_FlashFiredAutoModeReturnLightNotDetectedRedEyeReductionMode            = 0x005D,
    SYMetadataExifFlash_FlashFiredAutoModeReturnLightDetectedRedEyeReductionMode               = 0x005F,
} SYMetadataExifFlash;

@interface SYMetadataExif : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSNumber              *exposureTime;
@property SYMETADATA_PROPERTY_COPY NSNumber              *fNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber              *exposureProgram;
@property SYMETADATA_PROPERTY_COPY NSString              *spectralSensitivity;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *isoSpeedRatings;
@property SYMETADATA_PROPERTY_COPY NSObject              *oecf;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *version;
@property SYMETADATA_PROPERTY_COPY NSString              *dateTimeOriginal;
@property SYMETADATA_PROPERTY_COPY NSString              *dateTimeDigitized;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *componentsConfiguration;
@property SYMETADATA_PROPERTY_COPY NSNumber              *compressedBitsPerPixel;
@property SYMETADATA_PROPERTY_COPY NSNumber              *shutterSpeedValue;
@property SYMETADATA_PROPERTY_COPY NSNumber              *apertureValue;
@property SYMETADATA_PROPERTY_COPY NSNumber              *brightnessValue;
@property SYMETADATA_PROPERTY_COPY NSNumber              *exposureBiasValue;
@property SYMETADATA_PROPERTY_COPY NSNumber              *maxApertureValue;
@property SYMETADATA_PROPERTY_COPY NSNumber              *subjectDistance;
@property SYMETADATA_PROPERTY_COPY NSNumber              *meteringMode;
@property SYMETADATA_PROPERTY_COPY NSNumber              *lightSource;
@property SYMETADATA_PROPERTY_COPY NSNumber              *flash;
@property SYMETADATA_PROPERTY_COPY NSString              *flashString;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focalLength;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *subjectArea;
@property SYMETADATA_PROPERTY_COPY NSObject              *makerNote;
@property SYMETADATA_PROPERTY_COPY NSString              *userComment;
@property SYMETADATA_PROPERTY_COPY NSString              *subsecTime;
@property SYMETADATA_PROPERTY_COPY NSString              *subsecTimeOriginal;
@property SYMETADATA_PROPERTY_COPY NSString              *subsecTimeDigitized;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *flashPixVersion;
@property SYMETADATA_PROPERTY_COPY NSNumber              *colorSpace;
@property SYMETADATA_PROPERTY_COPY NSNumber              *pixelXDimension;
@property SYMETADATA_PROPERTY_COPY NSNumber              *pixelYDimension;
@property SYMETADATA_PROPERTY_COPY NSString              *relatedSoundFile;
@property SYMETADATA_PROPERTY_COPY NSNumber              *flashEnergy;
@property SYMETADATA_PROPERTY_COPY NSObject              *spatialFrequencyResponse;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focalPlaneXResolution;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focalPlaneYResolution;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focalPlaneResolutionUnit;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *subjectLocation;
@property SYMETADATA_PROPERTY_COPY NSNumber              *exposureIndex;
@property SYMETADATA_PROPERTY_COPY NSNumber              *sensingMethod;
@property SYMETADATA_PROPERTY_COPY NSObject              *fileSource;
@property SYMETADATA_PROPERTY_COPY NSObject              *sceneType;
@property SYMETADATA_PROPERTY_COPY NSArray               *cfaPattern;
@property SYMETADATA_PROPERTY_COPY NSNumber              *customRendered;
@property SYMETADATA_PROPERTY_COPY NSNumber              *exposureMode;
@property SYMETADATA_PROPERTY_COPY NSNumber              *whiteBalance;
@property SYMETADATA_PROPERTY_COPY NSNumber              *digitalZoomRatio;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focalLenIn35mmFilm;
@property SYMETADATA_PROPERTY_COPY NSNumber              *sceneCaptureType;
@property SYMETADATA_PROPERTY_COPY NSNumber              *gainControl;
@property SYMETADATA_PROPERTY_COPY NSNumber              *contrast;
@property SYMETADATA_PROPERTY_COPY NSNumber              *saturation;
@property SYMETADATA_PROPERTY_COPY NSNumber              *sharpness;
@property SYMETADATA_PROPERTY_COPY NSObject              *deviceSettingDescription;
@property SYMETADATA_PROPERTY_COPY NSNumber              *subjectDistRange;
@property SYMETADATA_PROPERTY_COPY NSString              *imageUniqueID;
@property SYMETADATA_PROPERTY_COPY NSString              *cameraOwnerName;
@property SYMETADATA_PROPERTY_COPY NSString              *bodySerialNumber;
@property SYMETADATA_PROPERTY_COPY NSArray               *lensSpecification;
@property SYMETADATA_PROPERTY_COPY NSString              *lensMake;
@property SYMETADATA_PROPERTY_COPY NSString              *lensModel;
@property SYMETADATA_PROPERTY_COPY NSString              *lensSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber              *gamma;
@property SYMETADATA_PROPERTY_COPY NSNumber              *sensitivityType;
@property SYMETADATA_PROPERTY_COPY NSNumber              *standardOutputSensitivity;
@property SYMETADATA_PROPERTY_COPY NSNumber              *recommendedExposureIndex;
@property SYMETADATA_PROPERTY_COPY NSNumber              *isoSpeed;
@property SYMETADATA_PROPERTY_COPY NSNumber              *isoSpeedLatitudeyyy;
@property SYMETADATA_PROPERTY_COPY NSNumber              *isoSpeedLatitudezzz;

@end


