//
//  SYMetadataMakerNikon.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

typedef enum : NSUInteger {
    SYMetadataMakerNikonShootingMode_Continuous             = 1 << 0L,
    SYMetadataMakerNikonShootingMode_Delay                  = 1 << 1L,
    SYMetadataMakerNikonShootingMode_PCControl              = 1 << 2L,
    SYMetadataMakerNikonShootingMode_Selftimer              = 1 << 3L,
    SYMetadataMakerNikonShootingMode_ExposureBracketing     = 1 << 4L,
    SYMetadataMakerNikonShootingMode_AutoISO                = 1 << 5L,
    SYMetadataMakerNikonShootingMode_WhiteBalanceBracketing = 1 << 6L,
    SYMetadataMakerNikonShootingMode_IRControl              = 1 << 7L,
    SYMetadataMakerNikonShootingMode_DLightingBracketing    = 1 << 8L,
} SYMetadataMakerNikonShootingMode;

typedef enum : NSUInteger {
    SYMetadataMakerNikonLensType_MF = 1 << 0L,
    SYMetadataMakerNikonLensType_D  = 1 << 1L,
    SYMetadataMakerNikonLensType_G  = 1 << 2L,
    SYMetadataMakerNikonLensType_VR = 1 << 3L,
} SYMetadataMakerNikonLensType;

@interface SYMetadataMakerNikon : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *isoSetting;
@property SYMETADATA_PROPERTY_COPY NSString              *colorMode;
@property SYMETADATA_PROPERTY_COPY NSString              *quality;
@property SYMETADATA_PROPERTY_COPY NSString              *whiteBalanceMode;
@property SYMETADATA_PROPERTY_COPY NSString              *sharpenMode;
@property SYMETADATA_PROPERTY_COPY NSString              *focusMode;
@property SYMETADATA_PROPERTY_COPY NSString              *flashSetting;
@property SYMETADATA_PROPERTY_COPY NSString              *isoSelection;
@property SYMETADATA_PROPERTY_COPY NSObject              *flashExposureComp;
@property SYMETADATA_PROPERTY_COPY NSString              *imageAdjustment;
@property SYMETADATA_PROPERTY_COPY NSObject              *lensAdapter;
@property SYMETADATA_PROPERTY_COPY NSNumber              *lensType;
@property SYMETADATA_PROPERTY_COPY NSObject              *lensInfo;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focusDistance;
@property SYMETADATA_PROPERTY_COPY NSNumber              *digitalZoom;
@property SYMETADATA_PROPERTY_COPY NSNumber              *shootingMode;
@property SYMETADATA_PROPERTY_COPY NSString              *cameraSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber              *shutterCount;

@end
