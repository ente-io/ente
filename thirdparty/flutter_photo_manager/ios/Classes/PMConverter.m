//
// Created by jinglong cai on 2021/4/13.
//

#import "PMConverter.h"
#import "PMImport.h"

@implementation PMConverter {

}

- (id)convertData:(NSData *)data {
  return [FlutterStandardTypedData typedDataWithBytes:data];
}

@end