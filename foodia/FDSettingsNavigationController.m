//
//  FDSettingsNavigationController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDSettingsNavigationController.h"
#import "ECSlidingViewController.h"
#import "FDMenuViewController.h"

@interface FDSettingsNavigationController ()

@end

@implementation FDSettingsNavigationController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FDMenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

@end