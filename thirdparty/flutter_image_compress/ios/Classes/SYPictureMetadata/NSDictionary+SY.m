//
//  NSDictionary+SY.m
//  SYPictureMetadataExample
//
//  Created by Stanislas Chevallier on 03/02/2017.
//  Copyright © 2017 Syan. All rights reserved.
//

#import "NSDictionary+SY.h"

@implementation NSDictionary (SY)

+ (NSDictionary *)sy_differencesFrom:(NSDictionary *)dictionaryOld
                                  to:(NSDictionary *)dictionaryNew
                 includeValuesInDiff:(BOOL)includeValuesInDiff;
{
    NSString *formatAdded    = (includeValuesInDiff ? @"Added: %@"          : @"Added"  );
    NSString *formatUpdated  = (includeValuesInDiff ? @"Updated: %@ -> %@"  : @"Updated");
    NSString *formatRemoved  = (includeValuesInDiff ? @"Removed: %@"        : @"Removed");
    
    NSMutableSet *allKeys = [NSMutableSet set];
    [allKeys addObjectsFromArray:dictionaryOld.allKeys];
    [allKeys addObjectsFromArray:dictionaryNew.allKeys];
    
    NSMutableDictionary *diffs = [[NSMutableDictionary alloc] init];
    for (id key in allKeys)
    {
        id valueOld = dictionaryOld[key];
        id valueNew = dictionaryNew[key];
        
        if (valueOld && valueNew && [valueOld isEqual:valueNew])
            continue;
        
        BOOL oldIsNilOrDic = !valueOld || [valueOld isKindOfClass:[NSDictionary class]];
        BOOL newIsNilOrDic = !valueNew || [valueNew isKindOfClass:[NSDictionary class]];
        
        if (oldIsNilOrDic && newIsNilOrDic)
        {
            NSDictionary *subDiffs = [self sy_differencesFrom:valueOld
                                                           to:valueNew
                                          includeValuesInDiff:includeValuesInDiff];
            [diffs setObject:subDiffs forKey:key];
            continue;
        }
        
        NSString *valueOldString = [valueOld description];
        NSString *valueNewString = [valueNew description];
        
        if ([valueOld isKindOfClass:[NSArray class]])
            valueOldString = [valueOld componentsJoinedByString:@", "];
        if ([valueNew isKindOfClass:[NSArray class]])
            valueNewString = [valueNew componentsJoinedByString:@", "];
        
        if ( valueOld && !valueNew)
        {
            [diffs setObject:[NSString stringWithFormat:formatRemoved, valueOldString]
                      forKey:key];
            continue;
        }
        
        if (!valueOld &&  valueNew)
        {
            [diffs setObject:[NSString stringWithFormat:formatAdded, valueNewString]
                      forKey:key];
            continue;
        }
        
        [diffs setObject:[NSString stringWithFormat:formatUpdated, valueOldString, valueNewString]
                  forKey:key];
    }
    
    return [diffs copy];
}

- (NSArray <NSString *> *)sy_allKeypaths
{
    NSMutableArray <NSString *> *keypaths = [NSMutableArray array];
    
    for (id key in self.allKeys)
    {
        NSString *keyString = [key description];
        [keypaths addObject:keyString];
        
        id value = self[key];
        if ([value isKindOfClass:[NSDictionary class]])
        {
            for (NSString *subKeypath in [(NSDictionary *)value sy_allKeypaths])
                [keypaths addObject:[@[keyString, subKeypath] componentsJoinedByString:@"."]];
        }
    }
    
    return [keypaths copy];
}

@end
