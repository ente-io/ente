//
//  SYMetadataExifAux.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

@interface SYMetadataExifAux : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *lensInfo;
@property SYMETADATA_PROPERTY_COPY NSString              *lensModel;
@property SYMETADATA_PROPERTY_COPY NSString              *serialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber              *lensID;
@property SYMETADATA_PROPERTY_COPY NSString              *lensSerialNumber;
@property SYMETADATA_PROPERTY_COPY NSNumber              *imageNumber;
@property SYMETADATA_PROPERTY_COPY NSObject              *flashCompensation;
@property SYMETADATA_PROPERTY_COPY NSString              *ownerName;
@property SYMETADATA_PROPERTY_COPY NSObject              *firmware;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focusMode;
@property SYMETADATA_PROPERTY_COPY NSNumber              *focusDistance;
@property SYMETADATA_PROPERTY_COPY NSArray               *afInfo;
@property SYMETADATA_PROPERTY_COPY NSNumber              *imageStabilization;

@end
