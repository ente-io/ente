//
//  SYMetadata.m
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/13/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "SYMetadata.h"
#import "NSDictionary+SY.h"

#if !TARGET_OS_TV
#import <AssetsLibrary/AssetsLibrary.h>
#endif

#define SYKeyForMetadata(name)          NSStringFromSelector(@selector(metadata##name))
#define SYDictionaryForMetadata(name)   SYPaste(SYPaste(kCGImageProperty,name),Dictionary)
#define SYClassForMetadata(name)        SYPaste(SYMetadata,name)
#define SYMappingPptyToClass(name)      SYKeyForMetadata(name):SYClassForMetadata(name).class
#define SYMappingPptyToKeyPath(name)    SYKeyForMetadata(name):(__bridge NSString *)SYDictionaryForMetadata(name)

@interface SYMetadata (Private)
- (void)refresh:(BOOL)force;
@end

@implementation SYMetadata

#pragma mark - Initialization

+ (instancetype)metadataWithDictionary:(NSDictionary *)dictionary
{
    if (!dictionary)
        return nil;
    
    NSError *error;
    
    SYMetadata *instance = [MTLJSONAdapter modelOfClass:self.class fromJSONDictionary:dictionary error:&error];
    
    if (instance)
        instance->_originalDictionary = dictionary;
        
    if (error)
        NSLog(@"--> Error creating %@ object: %@", NSStringFromClass(self.class), error);
    
    return instance;
}

+ (instancetype)metadataWithAsset:(ALAsset *)asset
{
#if !TARGET_OS_TV
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    return [self metadataWithDictionary:[representation metadata]];
#else
    return nil;
#endif
}

+ (instancetype)metadataWithAssetURL:(NSURL *)assetURL
{
    NSDictionary *dictionary = [self dictionaryWithAssetURL:assetURL];
    return [self metadataWithDictionary:dictionary];
}

+ (instancetype)metadataWithFileURL:(NSURL *)fileURL
{
    if (!fileURL)
        return nil;
    
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
    if (source == NULL)
        return nil;
    
    NSDictionary *dictionary;
    
    NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache:@(NO)};
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    if (properties) {
        dictionary = (__bridge NSDictionary*)properties;
    }
    
    CFRelease(source);
    
    return [self metadataWithDictionary:dictionary];
}

+ (instancetype)metadataWithImageData:(NSData *)imageData
{
    if (!imageData.length)
        return nil;
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    if (source == NULL)
        return nil;
    
    NSDictionary *dictionary;
    
    NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache:@(NO)};
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    if (properties) {
        dictionary = (__bridge NSDictionary*)properties;
    }
    
    CFRelease(source);
    
    return [self metadataWithDictionary:dictionary];
}

#pragma mark - Writing

// https://github.com/Nikita2k/SimpleExif/blob/master/Classes/ios/UIImage%2BExif.m
+ (NSData *)dataWithImageData:(NSData *)imageData andMetadata:(SYMetadata *)metadata
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    if (!source) {
        NSLog(@"Error: Could not create image source");
        return nil;
    }
    
    CFStringRef sourceImageType = CGImageSourceGetType(source);
    
    // create a new data object and write the new image into it
    NSMutableData *data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, sourceImageType, 1, NULL);
    
    if (!destination) {
        NSLog(@"Error: Could not create image destination");
        CFRelease(source);
        return nil;
    }
    
    // add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata.generatedDictionary);
    BOOL success = CGImageDestinationFinalize(destination);
    
    if (!success)
        NSLog(@"Error: Could not create data from image destination");
    
    CFRelease(destination);
    CFRelease(source);
    
    return (success ? data : nil);
}

#pragma mark - Getting metadata

+ (NSDictionary *)dictionaryWithAssetURL:(NSURL *)assetURL
{
#if !TARGET_OS_TV
    __block ALAsset *assetAtUrl = nil;
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        assetAtUrl = asset;
        dispatch_semaphore_signal(sema);
    } failureBlock:^(NSError *error) {
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (!assetAtUrl)
        return nil;
    
    ALAssetRepresentation *representation = [assetAtUrl defaultRepresentation];
    return [representation metadata];
#else
    return nil;
#endif
}

#pragma mark - Mapping

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary <NSString *, NSString *> *mappings = [NSMutableDictionary dictionary];
    [mappings
     addEntriesFromDictionary:@{SYMappingPptyToKeyPath(TIFF),
                                SYMappingPptyToKeyPath(Exif),
                                SYMappingPptyToKeyPath(GIF),
                                SYMappingPptyToKeyPath(JFIF),
                                SYMappingPptyToKeyPath(PNG),
                                SYMappingPptyToKeyPath(IPTC),
                                SYMappingPptyToKeyPath(GPS),
                                SYMappingPptyToKeyPath(Raw),
                                SYMappingPptyToKeyPath(CIFF),
                                SYMappingPptyToKeyPath(MakerCanon),
                                SYMappingPptyToKeyPath(MakerNikon),
                                SYMappingPptyToKeyPath(MakerMinolta),
                                SYMappingPptyToKeyPath(MakerFuji),
                                SYMappingPptyToKeyPath(MakerOlympus),
                                SYMappingPptyToKeyPath(MakerPentax),
                                SYMappingPptyToKeyPath(8BIM),
                                SYMappingPptyToKeyPath(DNG),
                                SYMappingPptyToKeyPath(ExifAux),
                                }];
    
    [mappings
     addEntriesFromDictionary:@{SYStringSel(fileSize):      (NSString *)kCGImagePropertyFileSize,
                                SYStringSel(pixelHeight):   (NSString *)kCGImagePropertyPixelHeight,
                                SYStringSel(pixelWidth):    (NSString *)kCGImagePropertyPixelWidth,
                                SYStringSel(dpiHeight):     (NSString *)kCGImagePropertyDPIHeight,
                                SYStringSel(dpiWidth):      (NSString *)kCGImagePropertyDPIWidth,
                                SYStringSel(depth):         (NSString *)kCGImagePropertyDepth,
                                SYStringSel(orientation):   (NSString *)kCGImagePropertyOrientation,
                                SYStringSel(isFloat):       (NSString *)kCGImagePropertyIsFloat,
                                SYStringSel(isIndexed):     (NSString *)kCGImagePropertyIsIndexed,
                                SYStringSel(hasAlpha):      (NSString *)kCGImagePropertyHasAlpha,
                                SYStringSel(colorModel):    (NSString *)kCGImagePropertyColorModel,
                                SYStringSel(profileName):   (NSString *)kCGImagePropertyProfileName,
                                
                                SYStringSel(metadataApple):         (NSString *)kCGImagePropertyMakerAppleDictionary,
                                SYStringSel(metadataPictureStyle):  (NSString *)kSYImagePropertyPictureStyle,
                                }];
    
    return [mappings copy];
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    static dispatch_once_t onceToken;
    static NSDictionary <NSString *, Class> *classMappings;
    dispatch_once(&onceToken, ^{
        classMappings = @{SYMappingPptyToClass(TIFF),
                          SYMappingPptyToClass(Exif),
                          SYMappingPptyToClass(GIF),
                          SYMappingPptyToClass(JFIF),
                          SYMappingPptyToClass(PNG),
                          SYMappingPptyToClass(IPTC),
                          SYMappingPptyToClass(GPS),
                          SYMappingPptyToClass(Raw),
                          SYMappingPptyToClass(CIFF),
                          SYMappingPptyToClass(MakerCanon),
                          SYMappingPptyToClass(MakerNikon),
                          SYMappingPptyToClass(MakerMinolta),
                          SYMappingPptyToClass(MakerFuji),
                          SYMappingPptyToClass(MakerOlympus),
                          SYMappingPptyToClass(MakerPentax),
                          SYMappingPptyToClass(8BIM),
                          SYMappingPptyToClass(DNG),
                          SYMappingPptyToClass(ExifAux),
                          };
    });
    
    
    Class objectClass = classMappings[key];
    
    if (objectClass)
        return [NSValueTransformer sy_dictionaryTransformerForModelOfClass:objectClass];
    
    return [super JSONTransformerForKey:key];
}

#pragma mark - Tests

- (NSDictionary *)differencesFromOriginalMetadataToModel
{
    return [NSDictionary sy_differencesFrom:self.originalDictionary
                                         to:[self generatedDictionary]
                        includeValuesInDiff:YES];
}

@end
