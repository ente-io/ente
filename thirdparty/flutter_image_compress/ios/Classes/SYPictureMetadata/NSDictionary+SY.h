//
//  NSDictionary+SY.h
//  SYPictureMetadataExample
//
//  Created by Stanislas Chevallier on 03/02/2017.
//  Copyright © 2017 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SY)

+ (NSDictionary *)sy_differencesFrom:(NSDictionary *)dictionaryOld
                                  to:(NSDictionary *)dictionaryNew
                 includeValuesInDiff:(BOOL)includeValuesInDiff;

- (NSArray <NSString *> *)sy_allKeypaths;

@end
