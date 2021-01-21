//
// Created by cjl on 2018/9/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (scale)

- (UIImage *)scaleWithMinWidth:(CGFloat)minWidth minHeight:(CGFloat)minHeight;
- (UIImage *)rotate:(CGFloat) rotate;
@end
