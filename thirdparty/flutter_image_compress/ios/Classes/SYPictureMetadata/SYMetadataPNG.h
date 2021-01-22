//
//  SYMetadataPNG.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"
#import <ImageIO/ImageIO.h>

typedef enum : NSUInteger {
    SYMetadataPNGsRGBIntent_Perceptual              = 0,
    SYMetadataPNGsRGBIntent_RelativeColorimetric    = 1,
    SYMetadataPNGsRGBIntent_Saturation              = 2,
    SYMetadataPNGsRGBIntent_AbsoluteColorimetric    = 3,
} SYMetadataPNGsRGBIntent;


typedef enum : NSUInteger {
    SYMetadataPNGCompressionFilter_NoFilters    = IMAGEIO_PNG_NO_FILTERS,
    SYMetadataPNGCompressionFilter_None         = IMAGEIO_PNG_FILTER_NONE,
    SYMetadataPNGCompressionFilter_Sub          = IMAGEIO_PNG_FILTER_SUB,
    SYMetadataPNGCompressionFilter_Up           = IMAGEIO_PNG_FILTER_UP,
    SYMetadataPNGCompressionFilter_Avg          = IMAGEIO_PNG_FILTER_AVG,
    SYMetadataPNGCompressionFilter_Paeth        = IMAGEIO_PNG_FILTER_PAETH,
    SYMetadataPNGCompressionFilter_All          = IMAGEIO_PNG_ALL_FILTERS,
} SYMetadataPNGCompressionFilter;


@interface SYMetadataPNG : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSNumber              *gamma;
@property SYMETADATA_PROPERTY_COPY NSNumber              *interlaceType;
@property SYMETADATA_PROPERTY_COPY NSNumber              *xPixelsPerMeter;
@property SYMETADATA_PROPERTY_COPY NSNumber              *yPixelsPerMeter;
@property SYMETADATA_PROPERTY_COPY NSNumber              *sRGBIntent;
@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *chromaticities;
@property SYMETADATA_PROPERTY_COPY NSString              *author;
@property SYMETADATA_PROPERTY_COPY NSString              *copyright;
@property SYMETADATA_PROPERTY_COPY NSString              *creationTime;
@property SYMETADATA_PROPERTY_COPY NSString              *descr;
@property SYMETADATA_PROPERTY_COPY NSString              *modificationTime;
@property SYMETADATA_PROPERTY_COPY NSString              *software;
@property SYMETADATA_PROPERTY_COPY NSString              *title;
@property SYMETADATA_PROPERTY_COPY NSNumber              *loopCount;
@property SYMETADATA_PROPERTY_COPY NSNumber              *delayTime;
@property SYMETADATA_PROPERTY_COPY NSNumber              *unclampedDelayTime;
@property SYMETADATA_PROPERTY_COPY NSNumber              *compressionFilter;

@end
