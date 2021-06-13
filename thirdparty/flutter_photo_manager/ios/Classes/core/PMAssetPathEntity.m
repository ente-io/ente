//
// Created by Caijinglong on 2019-09-06.
//

#import <Photos/Photos.h>
#import "PMAssetPathEntity.h"


@implementation PMAssetPathEntity {

}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.assetCount = 0;
    self.type = PM_TYPE_ALBUM;
  }

  return self;
}


- (instancetype)initWithId:(NSString *)id name:(NSString *)name assetCount:(NSUInteger)assetCount {
  self = [super init];
  if (self) {
    self.id = id;
    self.name = name;
    self.assetCount = assetCount;
    self.type = PM_TYPE_ALBUM;
  }

  return self;
}

+ (instancetype)entityWithId:(NSString *)id name:(NSString *)name assetCount:(NSUInteger)assetCount {
  return [[self alloc] initWithId:id name:name assetCount:assetCount];
}

@end


@implementation PMAssetEntity {

}
- (instancetype)initWithId:(NSString *)id createDt:(long)createDt width:(NSUInteger)width height:(NSUInteger)height
                  duration:(long)duration type:(int)type {
  self = [super init];
  if (self) {
    self.id = id;
    self.createDt = createDt;
    self.width = width;
    self.height = height;
    self.duration = duration;
    self.type = type;
  }

  return self;
}

+ (instancetype)entityWithId:(NSString *)id createDt:(long)createDt width:(NSUInteger)width height:(NSUInteger)height
                    duration:(long)duration type:(int)type {
  return [[self alloc] initWithId:id createDt:createDt width:width height:height duration:duration type:type];
}


@end
