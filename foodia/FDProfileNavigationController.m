//
//  FDProfileNavigationController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/2/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDProfileNavigationController.h"
#import "ECSlidingViewController.h"
#import "FDProfileViewController.h"
#import "FDMenuViewController.h"

@interface FDProfileNavigationController ()
@end

@implementation FDProfileNavigationController
@synthesize userId;
- (void)viewWillAppear:(BOOL)animated
{
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FDMenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [super viewWillAppear:animated];
}

@end