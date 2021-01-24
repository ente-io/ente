//
//  SYMetadataJFIF.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

@interface SYMetadataJFIF : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray     *version;
@property SYMETADATA_PROPERTY_COPY NSNumber    *xDensity;
@property SYMETADATA_PROPERTY_COPY NSNumber    *yDensity;
@property SYMETADATA_PROPERTY_COPY NSNumber    *densityUnit;
@property SYMETADATA_PROPERTY_COPY NSNumber    *isProgressive;

@end
