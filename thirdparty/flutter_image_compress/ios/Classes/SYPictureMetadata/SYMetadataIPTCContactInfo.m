//
//  SYMetadataIPTCContactInfo.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataIPTCContactInfo.h"
#import <ImageIO/ImageIO.h>

@implementation SYMetadataIPTCContactInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{SYStringSel(city):         (NSString *)kCGImagePropertyIPTCContactInfoCity,
             SYStringSel(country):      (NSString *)kCGImagePropertyIPTCContactInfoCountry,
             SYStringSel(address):      (NSString *)kCGImagePropertyIPTCContactInfoAddress,
             SYStringSel(postalCode):   (NSString *)kCGImagePropertyIPTCContactInfoPostalCode,
             SYStringSel(stateProvince):(NSString *)kCGImagePropertyIPTCContactInfoStateProvince,
             SYStringSel(emails):       (NSString *)kCGImagePropertyIPTCContactInfoEmails,
             SYStringSel(phones):       (NSString *)kCGImagePropertyIPTCContactInfoPhones,
             SYStringSel(webURLs):      (NSString *)kCGImagePropertyIPTCContactInfoWebURLs,
             };
}

@end
