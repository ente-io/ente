//
//  SYMetadataIPTC.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"
#import "SYMetadataIPTCContactInfo.h"

@interface SYMetadataIPTC : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSString              *objectTypeReference;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *objectAttributeReference;
@property SYMETADATA_PROPERTY_COPY NSString              *objectName;
@property SYMETADATA_PROPERTY_COPY NSString              *editStatus;
@property SYMETADATA_PROPERTY_COPY NSString              *editorialUpdate;
@property SYMETADATA_PROPERTY_COPY NSString              *urgency;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *subjectReference;
@property SYMETADATA_PROPERTY_COPY NSString              *category;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *supplementalCategory;
@property SYMETADATA_PROPERTY_COPY NSString              *fixtureIdentifier;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *keywords;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *contentLocationCode;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *contentLocationName;
@property SYMETADATA_PROPERTY_COPY NSString              *releaseDate;
@property SYMETADATA_PROPERTY_COPY NSString              *releaseTime;
@property SYMETADATA_PROPERTY_COPY NSString              *expirationDate;
@property SYMETADATA_PROPERTY_COPY NSString              *expirationTime;
@property SYMETADATA_PROPERTY_COPY NSString              *specialInstructions;
@property SYMETADATA_PROPERTY_COPY NSString              *actionAdvised;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *referenceService;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *referenceDate;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *referenceNumber;
@property SYMETADATA_PROPERTY_COPY NSString              *dateCreated;
@property SYMETADATA_PROPERTY_COPY NSString              *timeCreated;
@property SYMETADATA_PROPERTY_COPY NSString              *digitalCreationDate;
@property SYMETADATA_PROPERTY_COPY NSString              *digitalCreationTime;
@property SYMETADATA_PROPERTY_COPY NSString              *originatingProgram;
@property SYMETADATA_PROPERTY_COPY NSString              *programVersion;
@property SYMETADATA_PROPERTY_COPY NSString              *objectCycle;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *byline;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *bylineTitle;
@property SYMETADATA_PROPERTY_COPY NSString              *city;
@property SYMETADATA_PROPERTY_COPY NSString              *subLocation;
@property SYMETADATA_PROPERTY_COPY NSString              *provinceState;
@property SYMETADATA_PROPERTY_COPY NSString              *countryPrimaryLocationCode;
@property SYMETADATA_PROPERTY_COPY NSString              *countryPrimaryLocationName;
@property SYMETADATA_PROPERTY_COPY NSString              *originalTransmissionReference;
@property SYMETADATA_PROPERTY_COPY NSString              *headline;
@property SYMETADATA_PROPERTY_COPY NSString              *credit;
@property SYMETADATA_PROPERTY_COPY NSString              *source;
@property SYMETADATA_PROPERTY_COPY NSString              *copyrightNotice;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *contact;
@property SYMETADATA_PROPERTY_COPY NSString              *captionAbstract;
@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *writerEditor;
@property SYMETADATA_PROPERTY_COPY NSString              *imageType;
@property SYMETADATA_PROPERTY_COPY NSString              *imageOrientation;
@property SYMETADATA_PROPERTY_COPY NSString              *languageIdentifier;
@property SYMETADATA_PROPERTY_COPY NSNumber              *starRating;
@property SYMETADATA_PROPERTY_COPY SYMetadataIPTCContactInfo *creatorContactInfo;
@property SYMETADATA_PROPERTY_COPY NSString              *rightsUsageTerms;
@property SYMETADATA_PROPERTY_COPY NSString              *scene;

@end
