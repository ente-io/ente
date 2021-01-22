//
//  SYMetadataTIFF.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYMetadataBase.h"

typedef enum {
    SYPictureTiffOrientation_Unknown        = 0,
    SYPictureTiffOrientation_TopLeft        = 1,
    SYPictureTiffOrientation_TopRight       = 2,
    SYPictureTiffOrientation_BottomRight    = 3,
    SYPictureTiffOrientation_BottomLeft     = 4,
    SYPictureTiffOrientation_LeftTop        = 5,
    SYPictureTiffOrientation_RightTop       = 6,
    SYPictureTiffOrientation_RightBottom    = 7,
    SYPictureTiffOrientation_LeftBottom     = 8,
} SYPictureTiffOrientation;


typedef enum {
    SYPictureTiffPhotometricInterpretation_MINISWHITE   = 0,
    SYPictureTiffPhotometricInterpretation_MINISBLACK   = 1,
    SYPictureTiffPhotometricInterpretation_RGB          = 2,
    SYPictureTiffPhotometricInterpretation_PALETTE      = 3,
    SYPictureTiffPhotometricInterpretation_MASK         = 4,
    SYPictureTiffPhotometricInterpretation_SEPARATED    = 5,
    SYPictureTiffPhotometricInterpretation_YCBCR        = 6,
    SYPictureTiffPhotometricInterpretation_CIELAB       = 8,
    SYPictureTiffPhotometricInterpretation_ICCLAB       = 9,
    SYPictureTiffPhotometricInterpretation_ITULAB       = 10,
    SYPictureTiffPhotometricInterpretation_LOGL         = 32844,
    SYPictureTiffPhotometricInterpretation_LOGLUV       = 32845,
} SYPictureTiffPhotometricInterpretation;



@interface SYMetadataTIFF : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSNumber    *compression;
@property SYMETADATA_PROPERTY_COPY NSNumber    *photometricInterpretation;
@property SYMETADATA_PROPERTY_COPY NSString    *documentName;
@property SYMETADATA_PROPERTY_COPY NSString    *imageDescription;
@property SYMETADATA_PROPERTY_COPY NSString    *make;
@property SYMETADATA_PROPERTY_COPY NSString    *model;
@property SYMETADATA_PROPERTY_COPY NSNumber    *orientation;
@property SYMETADATA_PROPERTY_COPY NSNumber    *xResolution;
@property SYMETADATA_PROPERTY_COPY NSNumber    *yResolution;
@property SYMETADATA_PROPERTY_COPY NSNumber    *resolutionUnit;
@property SYMETADATA_PROPERTY_COPY NSString    *software;
@property SYMETADATA_PROPERTY_COPY NSArray     *transferFunction;
@property SYMETADATA_PROPERTY_COPY NSString    *dateTime;
@property SYMETADATA_PROPERTY_COPY NSString    *artist;
@property SYMETADATA_PROPERTY_COPY NSString    *hostComputer;
@property SYMETADATA_PROPERTY_COPY NSString    *copyright;
@property SYMETADATA_PROPERTY_COPY NSArray     *whitePoint;
@property SYMETADATA_PROPERTY_COPY NSArray     *primaryChromaticities;
@property SYMETADATA_PROPERTY_COPY NSNumber    *tileWidth;
@property SYMETADATA_PROPERTY_COPY NSNumber    *tileLength;

@end

