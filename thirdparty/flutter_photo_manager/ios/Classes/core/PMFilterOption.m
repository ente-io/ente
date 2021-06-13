//
// Created by Caijinglong on 2020/1/17.
//

#import "PMFilterOption.h"

@implementation PMFilterOptionGroup {
}

- (NSArray<NSSortDescriptor *> *)sortCond {
  return self.sortArray;
}

- (void)injectSortArray:(NSArray *)array {
  NSMutableArray<NSSortDescriptor *> *result = [NSMutableArray new];

  for (NSDictionary *dict in array) {
    int typeValue = [dict[@"type"] intValue];
    BOOL asc = [dict[@"asc"] boolValue];

    NSString *key = nil;
    if (typeValue == 0) {
      key = @"creationDate";
    } else if (typeValue == 1) {
      key = @"modificationDate";
    }

    if (key) {
      NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:asc];
      if (descriptor) {
        [result addObject:descriptor];
      }
    }
  }

  self.sortArray = result;
}
@end

@implementation PMFilterOption {

}
- (NSString *)sizeCond {
  return @"pixelWidth >= %d AND pixelWidth <=%d AND pixelHeight >= %d AND pixelHeight <=%d";
}

- (NSArray *)sizeArgs {
  PMSizeConstraint constraint = self.sizeConstraint;
  return @[@(constraint.minWidth), @(constraint.maxWidth), @(constraint.minHeight), @(constraint.maxHeight)];
}


- (NSString *)durationCond {
  return @"duration >= %f AND duration <= %f";
}

- (NSArray *)durationArgs {
  PMDurationConstraint constraint = self.durationConstraint;
  return @[@(constraint.minDuration), @(constraint.maxDuration)];
}

@end


@implementation PMDateOption {

}

- (NSString *)dateCond:(NSString *)key {
  NSMutableString *str = [NSMutableString new];

  [str appendString:@"AND "];
  [str appendString:@"( "];

  // min

  [str appendString:key];
  [str appendString:@" >= %@ "];


  // and
  [str appendString:@" AND "];

  // max

  [str appendString:key];
  [str appendString:@" <= %@ "];

  [str appendString:@") "];

  return str;
}

- (NSArray *)dateArgs {
  return @[self.min, self.max];
}

@end