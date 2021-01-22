//
//  SYMetadata8BIM.h
//  SYPictureMetadataExample
//
//  Created by Stan Chevallier on 12/16/12.
//  Copyright (c) 2012 Syan. All rights reserved.
//

#import "SYMetadataBase.h"

@interface SYMetadata8BIM : SYMetadataBase

@property SYMETADATA_PROPERTY_COPY NSArray <NSString *>  *layerNames;
@property SYMETADATA_PROPERTY_COPY NSNumber              *version;

@end
