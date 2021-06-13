//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>

#define PM_TYPE_ALBUM 1
#define PM_TYPE_FOLDER 2
@class PHAsset;

@interface PMAssetPathEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSUInteger assetCount;
@property(nonatomic, assign) BOOL isAll;
@property(nonatomic, assign) int type;
@property(nonatomic, assign) long modifiedDate;

- (instancetype)initWithId:(NSString *)id name:(NSString *)name assetCount:(NSUInteger)assetCount;

+ (instancetype)entityWithId:(NSString *)id name:(NSString *)name assetCount:(NSUInteger)assetCount;

@end

@interface PMAssetEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, assign) long createDt;
@property(nonatomic, assign) NSUInteger width;
@property(nonatomic, assign) NSUInteger height;
@property(nonatomic, assign) long duration;
@property(nonatomic, assign) int type;
@property(nonatomic, strong) PHAsset *phAsset;
@property(nonatomic, assign) long modifiedDt;
@property(nonatomic, assign) double lat;
@property(nonatomic, assign) double lng;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) BOOL favorite;

- (instancetype)initWithId:(NSString *)id
                  createDt:(long)createDt
                     width:(NSUInteger)width
                    height:(NSUInteger)height
                  duration:(long)duration
                      type:(int)type;

+ (instancetype)entityWithId:(NSString *)id
                    createDt:(long)createDt
                       width:(NSUInteger)width
                      height:(NSUInteger)height
                    duration:(long)duration
                        type:(int)type;

@end
