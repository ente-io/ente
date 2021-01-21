//
//  SYMetadataIPTC.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataIPTC.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataIPTC

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(objectTypeReference):           (NSString *)kCGImagePropertyIPTCObjectTypeReference,
             SYStringSel(objectAttributeReference):      (NSString *)kCGImagePropertyIPTCObjectAttributeReference,
             SYStringSel(objectName):                    (NSString *)kCGImagePropertyIPTCObjectName,
             SYStringSel(editStatus):                    (NSString *)kCGImagePropertyIPTCEditStatus,
             SYStringSel(editorialUpdate):               (NSString *)kCGImagePropertyIPTCEditorialUpdate,
             SYStringSel(urgency):                       (NSString *)kCGImagePropertyIPTCUrgency,
             SYStringSel(subjectReference):              (NSString *)kCGImagePropertyIPTCSubjectReference,
             SYStringSel(category):                      (NSString *)kCGImagePropertyIPTCCategory,
             SYStringSel(supplementalCategory):          (NSString *)kCGImagePropertyIPTCSupplementalCategory,
             SYStringSel(fixtureIdentifier):             (NSString *)kCGImagePropertyIPTCFixtureIdentifier,
             SYStringSel(keywords):                      (NSString *)kCGImagePropertyIPTCKeywords,
             SYStringSel(contentLocationCode):           (NSString *)kCGImagePropertyIPTCContentLocationCode,
             SYStringSel(contentLocationName):           (NSString *)kCGImagePropertyIPTCContentLocationName,
             SYStringSel(releaseDate):                   (NSString *)kCGImagePropertyIPTCReleaseDate,
             SYStringSel(releaseTime):                   (NSString *)kCGImagePropertyIPTCReleaseTime,
             SYStringSel(expirationDate):                (NSString *)kCGImagePropertyIPTCExpirationDate,
             SYStringSel(expirationTime):                (NSString *)kCGImagePropertyIPTCExpirationTime,
             SYStringSel(specialInstructions):           (NSString *)kCGImagePropertyIPTCSpecialInstructions,
             SYStringSel(actionAdvised):                 (NSString *)kCGImagePropertyIPTCActionAdvised,
             SYStringSel(referenceService):              (NSString *)kCGImagePropertyIPTCReferenceService,
             SYStringSel(referenceDate):                 (NSString *)kCGImagePropertyIPTCReferenceDate,
             SYStringSel(referenceNumber):               (NSString *)kCGImagePropertyIPTCReferenceNumber,
             SYStringSel(dateCreated):                   (NSString *)kCGImagePropertyIPTCDateCreated,
             SYStringSel(timeCreated):                   (NSString *)kCGImagePropertyIPTCTimeCreated,
             SYStringSel(digitalCreationDate):           (NSString *)kCGImagePropertyIPTCDigitalCreationDate,
             SYStringSel(digitalCreationTime):           (NSString *)kCGImagePropertyIPTCDigitalCreationTime,
             SYStringSel(originatingProgram):            (NSString *)kCGImagePropertyIPTCOriginatingProgram,
             SYStringSel(programVersion):                (NSString *)kCGImagePropertyIPTCProgramVersion,
             SYStringSel(objectCycle):                   (NSString *)kCGImagePropertyIPTCObjectCycle,
             SYStringSel(byline):                        (NSString *)kCGImagePropertyIPTCByline,
             SYStringSel(bylineTitle):                   (NSString *)kCGImagePropertyIPTCBylineTitle,
             SYStringSel(city):                          (NSString *)kCGImagePropertyIPTCCity,
             SYStringSel(subLocation):                   (NSString *)kCGImagePropertyIPTCSubLocation,
             SYStringSel(provinceState):                 (NSString *)kCGImagePropertyIPTCProvinceState,
             SYStringSel(countryPrimaryLocationCode):    (NSString *)kCGImagePropertyIPTCCountryPrimaryLocationCode,
             SYStringSel(countryPrimaryLocationName):    (NSString *)kCGImagePropertyIPTCCountryPrimaryLocationName,
             SYStringSel(originalTransmissionReference): (NSString *)kCGImagePropertyIPTCOriginalTransmissionReference,
             SYStringSel(headline):                      (NSString *)kCGImagePropertyIPTCHeadline,
             SYStringSel(credit):                        (NSString *)kCGImagePropertyIPTCCredit,
             SYStringSel(source):                        (NSString *)kCGImagePropertyIPTCSource,
             SYStringSel(copyrightNotice):               (NSString *)kCGImagePropertyIPTCCopyrightNotice,
             SYStringSel(contact):                       (NSString *)kCGImagePropertyIPTCContact,
             SYStringSel(captionAbstract):               (NSString *)kCGImagePropertyIPTCCaptionAbstract,
             SYStringSel(writerEditor):                  (NSString *)kCGImagePropertyIPTCWriterEditor,
             SYStringSel(imageType):                     (NSString *)kCGImagePropertyIPTCImageType,
             SYStringSel(imageOrientation):              (NSString *)kCGImagePropertyIPTCImageOrientation,
             SYStringSel(languageIdentifier):            (NSString *)kCGImagePropertyIPTCLanguageIdentifier,
             SYStringSel(starRating):                    (NSString *)kCGImagePropertyIPTCStarRating,
             SYStringSel(creatorContactInfo):            (NSString *)kCGImagePropertyIPTCCreatorContactInfo,
             SYStringSel(rightsUsageTerms):              (NSString *)kCGImagePropertyIPTCRightsUsageTerms,
             SYStringSel(scene):                         (NSString *)kCGImagePropertyIPTCScene,
             };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:SYStringSel(creatorContactInfo)])
    {
        return [NSValueTransformer sy_dictionaryTransformerForModelOfClass:[SYMetadataIPTCContactInfo class]];
    }
    
    return [super JSONTransformerForKey:key];
}

@end
