//
//  SYMetadataBase.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

#if TARGET_IPHONE_SIMULATOR && __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
// keys needed for simulator < 9.0
//CFStringRef const kCGImagePropertyAPNGDelayTime                 = CFSTR("DelayTime");
//CFStringRef const kCGImagePropertyAPNGLoopCount                 = CFSTR("LoopCount");
//CFStringRef const kCGImagePropertyAPNGUnclampedDelayTime        = CFSTR("UnclampedDelayTime");
CFStringRef const kCGImagePropertyMakerFujiDictionary           = CFSTR("{MakerFuji}");
CFStringRef const kCGImagePropertyMakerMinoltaDictionary        = CFSTR("{MakerMinolta}");
CFStringRef const kCGImagePropertyMakerOlympusDictionary        = CFSTR("{MakerOlympus}");
CFStringRef const kCGImagePropertyMakerPentaxDictionary         = CFSTR("{MakerPentax}");
#endif

#if TARGET_IPHONE_SIMULATOR && __IPHONE_OS_VERSION_MIN_REQUIRED < 100000
// keys needed for simulator < 10.0
CFStringRef const kCGImageProperty8BIMVersion                   = CFSTR("Version");
#endif

#if !TARGET_IPHONE_SIMULATOR && __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
// keys available since iOS 8+, exported here for < 8.0
CFStringRef const kCGImagePropertyGPSHPositioningError          = CFSTR("HPositioningError");
#endif

#if !TARGET_IPHONE_SIMULATOR && __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
// keys available since iOS 9+, exported here for < 9.0
CFStringRef const kCGImagePropertyTIFFTileWidth                 = CFSTR("TileWidth");
CFStringRef const kCGImagePropertyTIFFTileLength                = CFSTR("TileLength");
CFStringRef const kCGImagePropertyPNGCompressionFilter          = CFSTR("kCGImagePropertyPNGCompressionFilter");
// keys available since iOS 8+ according to header, but not actually available...
//CFStringRef const kCGImagePropertyAPNGDelayTime                 = CFSTR("DelayTime");
//CFStringRef const kCGImagePropertyAPNGLoopCount                 = CFSTR("LoopCount");
//CFStringRef const kCGImagePropertyAPNGUnclampedDelayTime        = CFSTR("UnclampedDelayTime");
#endif

#if !TARGET_IPHONE_SIMULATOR && __IPHONE_OS_VERSION_MIN_REQUIRED < 100000
// keys available since iOS 8+ according to header, but not actually available...
CFStringRef const kCGImageProperty8BIMVersion                   = CFSTR("Version");
// keys available since iOS 10+, exported here for < 10.0
CFStringRef const kCGImagePropertyDNGBlackLevel                 = CFSTR("BlackLevel");
CFStringRef const kCGImagePropertyDNGWhiteLevel                 = CFSTR("WhiteLevel");
CFStringRef const kCGImagePropertyDNGCalibrationIlluminant1     = CFSTR("CalibrationIlluminant1");
CFStringRef const kCGImagePropertyDNGCalibrationIlluminant2     = CFSTR("CalibrationIlluminant2");
CFStringRef const kCGImagePropertyDNGColorMatrix1               = CFSTR("ColorMatrix1");
CFStringRef const kCGImagePropertyDNGColorMatrix2               = CFSTR("ColorMatrix2");
CFStringRef const kCGImagePropertyDNGCameraCalibration1         = CFSTR("CameraCalibration1");
CFStringRef const kCGImagePropertyDNGCameraCalibration2         = CFSTR("CameraCalibration2");
CFStringRef const kCGImagePropertyDNGAsShotNeutral              = CFSTR("AsShotNeutral");
CFStringRef const kCGImagePropertyDNGAsShotWhiteXY              = CFSTR("AsShotWhiteXY");
CFStringRef const kCGImagePropertyDNGBaselineExposure           = CFSTR("BaselineExposure");
CFStringRef const kCGImagePropertyDNGBaselineNoise              = CFSTR("BaselineNoise");
CFStringRef const kCGImagePropertyDNGBaselineSharpness          = CFSTR("BaselineSharpness");
CFStringRef const kCGImagePropertyDNGPrivateData                = CFSTR("DNGPrivateData");
CFStringRef const kCGImagePropertyDNGCameraCalibrationSignature = CFSTR("CameraCalibrationSignature");
CFStringRef const kCGImagePropertyDNGProfileCalibrationSignature= CFSTR("ProfileCalibrationSignature");
CFStringRef const kCGImagePropertyDNGNoiseProfile               = CFSTR("NoiseProfile");
CFStringRef const kCGImagePropertyDNGWarpRectilinear            = CFSTR("WarpRectilinear");
CFStringRef const kCGImagePropertyDNGWarpFisheye                = CFSTR("WarpFisheye");
CFStringRef const kCGImagePropertyDNGFixVignetteRadial          = CFSTR("FixVignetteRadial");
#endif

// not defined in ImageIO but still read by iOS
CFStringRef const kSYImagePropertyPictureStyle                  = CFSTR("{PictureStyle}");
CFStringRef const kSYImagePropertyExifAuxAutoFocusInfo          = CFSTR("AFInfo");
CFStringRef const kSYImagePropertyExifAuxImageStabilization     = CFSTR("ImageStabilization");
CFStringRef const kSYImagePropertyCIFFMaxAperture               = CFSTR("MaxAperture");
CFStringRef const kSYImagePropertyCIFFMinAperture               = CFSTR("MinAperture");
CFStringRef const kSYImagePropertyCIFFUniqueModelID             = CFSTR("UniqueModelID");

@implementation SYMetadataBase

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{};
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    // default transformer to prevents NSNull in generated dictionary
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}

+ (NSArray <NSString *> *)supportedKeys
{
    NSMutableArray <NSString *> *keys = [NSMutableArray array];
    
    NSDictionary *mappings = [self JSONKeyPathsByPropertyKey];
    for (NSString *key in mappings)
    {
        [keys addObject:mappings[key]];
        
        NSValueTransformer *transformer = [self JSONTransformerForKey:key];
        Class modelClass = [transformer sy_dictionaryTransformerModelClass];
        
        if ([(NSObject *)modelClass respondsToSelector:@selector(supportedKeys)])
        {
            NSArray <NSString *> *subkeys = [modelClass supportedKeys];
            for (NSString *subkey in subkeys)
                [keys addObject:[@[mappings[key], subkey] componentsJoinedByString:@"."]];
        }
    }
    
    return [keys copy];
}

- (NSDictionary *)generatedDictionary
{
    NSError *error;
    NSMutableDictionary *dictionary = [[MTLJSONAdapter JSONDictionaryFromModel:self error:&error] mutableCopy];
    
    if (error)
        NSLog(@"--> Error for class %@: %@", NSStringFromClass(self.class), error);
    
    [dictionary removeObjectsForKeys:[dictionary allKeysForObject:[NSNull null]]];
    return [dictionary copy];
}

@end

@implementation MTLValueTransformer (SY)

+ (instancetype)sy_nonZeroIntegerValueTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if ([value integerValue] == 0)
            return nil;
        return value;
    }];
}

@end

@implementation NSValueTransformer (SY)

+ (instancetype)sy_dictionaryTransformerForModelOfClass:(Class)modelClass
{
    NSValueTransformer <MTLTransformerErrorHandling> *instance = [MTLJSONAdapter dictionaryTransformerWithModelClass:modelClass];
    
    if (instance)
        objc_setAssociatedObject(instance, @selector(sy_dictionaryTransformerModelClass), NSStringFromClass(modelClass), OBJC_ASSOCIATION_COPY);
    
    return instance;
}

- (Class)sy_dictionaryTransformerModelClass
{
    NSString *classString = objc_getAssociatedObject(self, @selector(sy_dictionaryTransformerModelClass));
    return (classString ? NSClassFromString(classString) : nil);
}

@end

