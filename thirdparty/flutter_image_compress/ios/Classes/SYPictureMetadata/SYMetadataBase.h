//
//  SYMetadataBase.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#define SYPaste1(a,b)                   a##b
#define SYPaste(a,b)                    SYPaste1(a,b)
#define SYStringSel(sel)                NSStringFromSelector(@selector(sel))

// keys not available in public header, but still read by iOS
extern CFStringRef const kSYImagePropertyExifAuxAutoFocusInfo;
extern CFStringRef const kSYImagePropertyExifAuxImageStabilization;
extern CFStringRef const kSYImagePropertyCIFFMaxAperture;
extern CFStringRef const kSYImagePropertyCIFFMinAperture;
extern CFStringRef const kSYImagePropertyCIFFUniqueModelID;
extern CFStringRef const kSYImagePropertyPictureStyle;

// allows to easily switch between read-only and R/W properties
#define SYMETADATA_PROPERTY_COPY    (nonatomic, copy)
#define SYMETADATA_PROPERTY_STRONG  (nonatomic, strong)

@interface MTLValueTransformer (SY)
+ (instancetype)sy_nonZeroIntegerValueTransformer;
@end

@interface NSValueTransformer (SY)
+ (instancetype)sy_dictionaryTransformerForModelOfClass:(Class)modelClass;
- (Class)sy_dictionaryTransformerModelClass;
@end

@interface SYMetadataBase : MTLModel <MTLJSONSerializing>

- (NSDictionary *)generatedDictionary;
+ (NSArray <NSString *> *)supportedKeys;

@end
