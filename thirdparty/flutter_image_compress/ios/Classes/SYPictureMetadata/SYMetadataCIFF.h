//
//  SYMetadataCIFF.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

// https://raw.githubusercontent.com/wiki/drewnoakes/metadata-extractor/docs/CIFFspecV1R04.pdf

@interface SYMetadataCIFF : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSString  *descr;
@property SYMETADATA_PROPERTY_COPY NSString  *firmware;
@property SYMETADATA_PROPERTY_COPY NSString  *ownerName;
@property SYMETADATA_PROPERTY_COPY NSString  *imageName;
@property SYMETADATA_PROPERTY_COPY NSString  *imageFileName;
@property SYMETADATA_PROPERTY_COPY NSNumber  *releaseMethod;
@property SYMETADATA_PROPERTY_COPY NSNumber  *releaseTiming;
@property SYMETADATA_PROPERTY_COPY NSNumber  *recordID;
@property SYMETADATA_PROPERTY_COPY NSNumber  *selfTimingTime;
@property SYMETADATA_PROPERTY_COPY NSNumber  *cameraSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber  *imageSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber  *continuousDrive;
@property SYMETADATA_PROPERTY_COPY NSNumber  *focusMode;
@property SYMETADATA_PROPERTY_COPY NSNumber  *meteringMode;
@property SYMETADATA_PROPERTY_COPY NSNumber  *shootingMode;
@property SYMETADATA_PROPERTY_COPY NSString  *lensModel;
@property SYMETADATA_PROPERTY_COPY NSNumber  *lensMaxMM;
@property SYMETADATA_PROPERTY_COPY NSNumber  *lensMinMM;
@property SYMETADATA_PROPERTY_COPY NSNumber  *whiteBalanceIndex;
@property SYMETADATA_PROPERTY_COPY NSNumber  *flashExposureComp;
@property SYMETADATA_PROPERTY_COPY NSNumber  *measuredEV;
@property SYMETADATA_PROPERTY_COPY NSNumber  *uniqueModelID;
@property SYMETADATA_PROPERTY_COPY NSNumber  *maxAperture;
@property SYMETADATA_PROPERTY_COPY NSNumber  *minAperture;

@end
