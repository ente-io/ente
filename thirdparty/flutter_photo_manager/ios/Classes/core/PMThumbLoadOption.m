//
// Created by jinglong cai on 2020/9/25.
//

#import "PMThumbLoadOption.h"

@implementation PMThumbLoadOption {

}

+ (instancetype)optionDict:(NSDictionary *)dict {
    PMThumbLoadOption *option = [PMThumbLoadOption new];

    option.width = [dict[@"width"] intValue];
    option.height = [dict[@"height"] intValue];
    int quality = [dict[@"quality"] intValue];
    option.quality = (float) quality / 100;
    int format = [dict[@"format"] intValue];
    if (format == 0) {
        option.format = PMThumbFormatTypeJPEG;
    } else {
        option.format = PMThumbFormatTypePNG;
    }

    int dm = [dict[@"deliveryMode"] intValue];
    int rm = [dict[@"resizeMode"] intValue];
    int rcm = [dict[@"resizeContentMode"] intValue];

    PHImageRequestOptionsDeliveryMode deliveryMode;
    switch (dm) {
        case 0:
            deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        break;
        case 1:
            deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        break;
        case 2:
            deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        break;
        default:
            deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;

    }
    option.deliveryMode = deliveryMode;


    PHImageRequestOptionsResizeMode resizeMode;
    switch (rm) {
        case 0:
            resizeMode = PHImageRequestOptionsResizeModeNone;
        break;
        case 1:
            resizeMode = PHImageRequestOptionsResizeModeFast;
        break;
        case 2:
            resizeMode = PHImageRequestOptionsResizeModeExact;
        break;
        default:
            resizeMode = PHImageRequestOptionsResizeModeNone;

    }
    option.resizeMode = resizeMode;

    PHImageContentMode resizeContentMode;
    switch (rcm) {
        case 0:
            resizeContentMode = PHImageContentModeAspectFit;
        break;
        case 1:
            resizeContentMode = PHImageContentModeAspectFill;
        break;
        case 2:
            resizeContentMode = PHImageContentModeDefault;
        break;
        default:
            resizeContentMode = PHImageContentModeAspectFit;

    }
    option.contentMode = resizeContentMode;

    return option;
}

- (CGSize)makeSize {
  return CGSizeMake(self.width, self.height);
}


@end
