//
//  SYMetadataMakerCanon.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

typedef enum : NSUInteger {
   SYMetadataMakerCanonContinuousDriver_Single                  = 0,
   SYMetadataMakerCanonContinuousDriver_Continuous              = 1,
   SYMetadataMakerCanonContinuousDriver_Movie                   = 2,
   SYMetadataMakerCanonContinuousDriver_ContinuousSpeedPriority = 3,
   SYMetadataMakerCanonContinuousDriver_ContinuousLow           = 4,
   SYMetadataMakerCanonContinuousDriver_ContinuousHigh          = 5,
   SYMetadataMakerCanonContinuousDriver_SilentSingle            = 6,
   SYMetadataMakerCanonContinuousDriver_SingleSilent            = 9,
   SYMetadataMakerCanonContinuousDriver_ContinuousSilent        = 10,
} SYMetadataMakerCanonContinuousDriver;

@interface SYMetadataMakerCanon : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSString  *ownerName;
@property SYMETADATA_PROPERTY_COPY NSNumber  *cameraSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber  *imageSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber  *flashExposureComp;
@property SYMETADATA_PROPERTY_COPY NSNumber  *continuousDrive;
@property SYMETADATA_PROPERTY_COPY NSString  *lensModel;
@property SYMETADATA_PROPERTY_COPY NSString  *firmware;
@property SYMETADATA_PROPERTY_COPY NSNumber  *aspectRatioInfo;
@property SYMETADATA_PROPERTY_COPY NSNumber  *whiteBalanceIndex;
@property SYMETADATA_PROPERTY_COPY NSNumber  *uniqueModelID;
@property SYMETADATA_PROPERTY_COPY NSNumber  *maxAperture;
@property SYMETADATA_PROPERTY_COPY NSNumber  *minAperture;

@end
