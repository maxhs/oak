//
//  FDCategorySegue.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDCategorySegue.h"
#import "FDPostCategoryViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation FDCategorySegue

- (void)perform {
    
    // capture the feed view as a dummy image for the transition to the category view
    
    UINavigationController *sourceViewController = [(UIViewController *)self.sourceViewController navigationController];
    UINavigationController *destinationNavController = (UINavigationController *)self.destinationViewController;
    FDPostCategoryViewController *destinationViewController = (FDPostCategoryViewController *)[destinationNavController.viewControllers objectAtIndex:0];
    UIImage *resultingImage;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        UIGraphicsBeginImageContextWithOptions(sourceViewController.view.bounds.size, NO, 0.0f);
        [sourceViewController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        UIGraphicsBeginImageContextWithOptions(sourceViewController.view.window.bounds.size, NO, [UIScreen mainScreen].scale);
        [sourceViewController.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();;
    }
    
    destinationViewController.dummyImage = resultingImage;
    
    [self.sourceViewController presentViewController:self.destinationViewController animated:NO completion:^{ }];
    
}

@end
