//
// Created by Caijinglong on 2020/1/17.
//

#import <Foundation/Foundation.h>

@interface PMDateOption : NSObject

@property(nonatomic, strong) NSDate *min;
@property(nonatomic, strong) NSDate *max;
@property(nonatomic, assign) BOOL ignore;

- (NSString *)dateCond:(NSString *)key;

- (NSArray *)dateArgs;

@end

typedef struct PMSizeConstraint {

    unsigned int minWidth;
    unsigned int maxWidth;
    unsigned int minHeight;
    unsigned int maxHeight;
    BOOL ignoreSize;

} PMSizeConstraint;

typedef struct PMDurationConstraint {

    double minDuration;
    double maxDuration;

} PMDurationConstraint;

@interface PMFilterOption : NSObject

@property(nonatomic, assign) BOOL needTitle;
@property(nonatomic, assign) PMSizeConstraint sizeConstraint;
@property(nonatomic, assign) PMDurationConstraint durationConstraint;

- (NSString *)sizeCond;

- (NSArray *)sizeArgs;

- (NSString *)durationCond;

- (NSArray *)durationArgs;

@end

@interface PMFilterOptionGroup : NSObject

@property(nonatomic, strong) PMFilterOption *imageOption;
@property(nonatomic, strong) PMFilterOption *videoOption;
@property(nonatomic, strong) PMFilterOption *audioOption;
@property(nonatomic, strong) PMDateOption *dateOption;
@property(nonatomic, strong) PMDateOption *updateOption;
@property(nonatomic, assign) BOOL containsEmptyAlbum;
@property(nonatomic, assign) BOOL containsModified;
@property(nonatomic, strong) NSArray<NSSortDescriptor*> *sortArray;

- (NSArray<NSSortDescriptor *> *)sortCond;

- (void)injectSortArray:(NSArray *)array;
@end
