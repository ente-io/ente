//
// Created by Caijinglong on 2019-09-06.
//

#import "PMFileHelper.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void (^ChangeIds)(NSArray<NSString *> *);

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;
@class PMFilterOption;
@class PMFilterOptionGroup;
@class PMThumbLoadOption;

#import "PMProgressHandlerProtocol.h"
#import "PMResultHandler.h"
#import "PMConvertProtocol.h"

typedef void (^AssetResult)(PMAssetEntity *);

@interface PMManager : NSObject

@property(nonatomic, strong) NSObject <PMConvertProtocol> *converter;

- (BOOL)isAuth;

+ (void)openSetting;

- (void)setAuth:(BOOL)auth;

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type hasAll:(BOOL)hasAll onlyAll:(BOOL)onlyAll option:(PMFilterOptionGroup *)option;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page pageCount:(NSUInteger)pageCount filterOption:(PMFilterOptionGroup *)filterOption;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId;

- (void)clearCache;

- (void)getThumbWithId:(NSString *)id1 option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler;

- (void)getFullSizeFileWithId:(NSString *)id isOrigin:(BOOL)isOrigin resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler;

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type filterOption:(PMFilterOptionGroup *)filterOption;

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id type:(NSUInteger)type start:(NSUInteger)start end:(NSUInteger)end filterOption:(PMFilterOptionGroup *)filterOption;

- (void)saveImage:(NSData *)data
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (BOOL)existsWithId:(NSString *)assetId;

- (NSString*)getTitleAsyncWithAssetId: (NSString *) assetId;

- (void)getMediaUrl:(NSString *)assetId resultHandler:(NSObject <PMResultHandler> *)handler;

- (NSArray<PMAssetPathEntity *> *)getSubPathWithId:(NSString *)id type:(int)type albumType:(int)albumType option:(PMFilterOptionGroup *)option;

- (void)saveImageWithPath:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(void (^)(PMAssetEntity *))block;

- (void)copyAssetWithId:(NSString *)id toGallery:(NSString *)gallery block:(void (^)(PMAssetEntity *entity, NSString *msg))block;

- (void)createFolderWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block;

- (void)createAlbumWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block;

- (void)removeInAlbumWithAssetId:(NSArray *)id albumId:(NSString *)albumId block:(void (^)(NSString *))block;

- (void)removeCollectionWithId:(NSString *)id type:(int)type block:(void (^)(NSString *))block;

- (BOOL)favoriteWithId:(NSString *)id favorite:(BOOL)favorite;

- (void)clearFileCache;

- (void)requestCacheAssetsThumb:(NSArray *)identifiers option:(PMThumbLoadOption *)option;

- (void)cancelCacheRequests;

- (void)injectModifyToDate:(PMAssetPathEntity *)path;
@end
