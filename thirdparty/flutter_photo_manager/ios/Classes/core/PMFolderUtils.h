//
// Created by Caijinglong on 2020/3/23.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PMFolderUtils : NSObject

+ (NSArray<PHCollectionList *> *)getRootFolderWithOptions:(PHFetchOptions *)options;

+ (BOOL)isRecentCollection:(NSString *)id1;

+ (NSArray <PHCollection *> *)getSubCollectionWithCollection:(PHCollectionList *)collection
                                                     options:(PHFetchOptions *)options;

+(void)debugInfo:(PHCollection*)collection ;

@end