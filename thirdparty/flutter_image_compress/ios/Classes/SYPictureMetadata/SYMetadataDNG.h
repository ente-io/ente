//
//  SYMetadataDNG.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

// https://www.adobe.com/content/dam/Adobe/en/products/photoshop/pdfs/dng_spec_1.4.0.0.pdf
@interface SYMetadataDNG : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *version;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *backwardVersion;
@property SYMETADATA_PROPERTY_COPY NSString              *uniqueCameraModel;
@property SYMETADATA_PROPERTY_COPY NSString              *localizedCameraModel;
@property SYMETADATA_PROPERTY_COPY NSString              *cameraSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *lensInfo;

@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *blackLevel;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *whiteLevel;
@property SYMETADATA_PROPERTY_COPY NSNumber              *calibrationIlluminant1;
@property SYMETADATA_PROPERTY_COPY NSNumber              *calibrationIlluminant2;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *colorMatrix1;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *colorMatrix2;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *cameraCalibration1;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *cameraCalibration2;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *asShotNeutral;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *asShotWhiteXY;
@property SYMETADATA_PROPERTY_COPY NSNumber              *baselineExposure;
@property SYMETADATA_PROPERTY_COPY NSNumber              *baselineNoise;
@property SYMETADATA_PROPERTY_COPY NSNumber              *baselineSharpness;
@property SYMETADATA_PROPERTY_COPY NSObject              *privateData;
@property SYMETADATA_PROPERTY_COPY NSString              *cameraCalibrationSignature;
@property SYMETADATA_PROPERTY_COPY NSString              *profileCalibrationSignature;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *noiseProfile;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *warpRectilinear;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *warpFisheye;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *fixVignetteRadial;

@end
