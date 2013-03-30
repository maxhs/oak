//
//  FDLoginSegue.m
//  foodia
//
//  Created by Max Haines-Stiles on 2/1/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDLoginSegue.h"
#import <QuartzCore/QuartzCore.h>

@implementation FDLoginSegue
- (void)perform
{
    UIViewController *destinationViewController = (UIViewController *)self.destinationViewController;
    UIViewController *sourceViewController = (UIViewController *)self.sourceViewController;
    
    UIGraphicsBeginImageContextWithOptions(sourceViewController.view.bounds.size, NO, 0.0f);
    [sourceViewController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *dummyImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *dummyView = [[UIImageView alloc] initWithImage:dummyImage];

    [destinationViewController.view addSubview:dummyView];
    
    [sourceViewController presentViewController:destinationViewController animated:NO completion:^{
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            dummyView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.15
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                CGAffineTransform transform = CGAffineTransformIdentity;
                dummyView.transform = CGAffineTransformTranslate(transform, -320, 0);
            } completion:^(BOOL finished) {
                [dummyView removeFromSuperview];
            }];
        }];
    }];
}
@end
