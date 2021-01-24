//
//  SYMetadataGIF.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

@interface SYMetadataGIF : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY   NSNumber                *loopCount;
@property SYMETADATA_PROPERTY_COPY   NSNumber                *delayTime;
@property SYMETADATA_PROPERTY_COPY   NSArray <NSNumber *>    *imageColorMap;
@property SYMETADATA_PROPERTY_COPY   NSNumber                *hasGlobalColorMap;
@property SYMETADATA_PROPERTY_COPY   NSNumber                *unclampedDelayTime;

@end
