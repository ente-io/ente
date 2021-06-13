//
// Created by jinglong cai on 2020/9/25.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef enum PMThumbFormatType {
  PMThumbFormatTypeJPEG,
  PMThumbFormatTypePNG,
} PMThumbFormatType;

@interface PMThumbLoadOption : NSObject

@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) PMThumbFormatType format;
@property(nonatomic, assign) float quality;

#pragma mark only iOS
@property(nonatomic, assign) PHImageContentMode contentMode;
@property(nonatomic, assign) PHImageRequestOptionsDeliveryMode deliveryMode;
@property(nonatomic, assign) PHImageRequestOptionsResizeMode resizeMode;

+ (instancetype)optionDict:(NSDictionary *)dict;

-(CGSize)makeSize;

@end