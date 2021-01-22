//
//  SYMetadataGPS.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

// TODO: use enum for refs instead of strings

@interface SYMetadataGPS : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray <NSNumber *>  *version;
@property SYMETADATA_PROPERTY_COPY NSString  *latitudeRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *latitude;
@property SYMETADATA_PROPERTY_COPY NSString  *longitudeRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *longitude;
@property SYMETADATA_PROPERTY_COPY NSNumber  *altitudeRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *altitude;
@property SYMETADATA_PROPERTY_COPY NSString  *timeStamp;
@property SYMETADATA_PROPERTY_COPY NSString  *satellites;
@property SYMETADATA_PROPERTY_COPY NSString  *status;
@property SYMETADATA_PROPERTY_COPY NSString  *measureMode;
@property SYMETADATA_PROPERTY_COPY NSNumber  *dop;
@property SYMETADATA_PROPERTY_COPY NSString  *speedRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *speed;
@property SYMETADATA_PROPERTY_COPY NSString  *trackRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *track;
@property SYMETADATA_PROPERTY_COPY NSString  *imgDirectionRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *imgDirection;
@property SYMETADATA_PROPERTY_COPY NSString  *mapDatum;
@property SYMETADATA_PROPERTY_COPY NSString  *destLatitudeRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *destLatitude;
@property SYMETADATA_PROPERTY_COPY NSString  *destLongitudeRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *destLongitude;
@property SYMETADATA_PROPERTY_COPY NSString  *destBearingRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *destBearing;
@property SYMETADATA_PROPERTY_COPY NSString  *destDistanceRef;
@property SYMETADATA_PROPERTY_COPY NSNumber  *destDistance;
@property SYMETADATA_PROPERTY_COPY NSString  *processingMethod;
@property SYMETADATA_PROPERTY_COPY NSObject  *areaInformation;
@property SYMETADATA_PROPERTY_COPY NSString  *dateStamp;
@property SYMETADATA_PROPERTY_COPY NSNumber  *differental;
@property SYMETADATA_PROPERTY_COPY NSNumber  *hPositioningError;

@end
