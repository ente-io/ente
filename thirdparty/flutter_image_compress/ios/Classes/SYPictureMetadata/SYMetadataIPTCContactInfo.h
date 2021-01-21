//
//  SYMetadataIPTCContactInfo.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

@interface SYMetadataIPTCContactInfo : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSString  *city;
@property SYMETADATA_PROPERTY_COPY NSString  *country;
@property SYMETADATA_PROPERTY_COPY NSString  *address;
@property SYMETADATA_PROPERTY_COPY NSString  *postalCode;
@property SYMETADATA_PROPERTY_COPY NSString  *stateProvince;
@property SYMETADATA_PROPERTY_COPY NSString  *emails;
@property SYMETADATA_PROPERTY_COPY NSString  *phones;
@property SYMETADATA_PROPERTY_COPY NSString  *webURLs;

@end
