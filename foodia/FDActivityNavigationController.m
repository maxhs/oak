//
//  FDActivityNavigationController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDActivityNavigationController.h"
#import "ECSlidingViewController.h"
#import "FDProfileViewController.h"
#import "FDMenuViewController.h"

@interface FDActivityNavigationController ()

@end

@implementation FDActivityNavigationController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logAllPageViews:self];
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FDMenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}


@end
