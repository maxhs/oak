//
//  FeedNavigationViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDFeedNavigationViewController.h"
#import "FDMenuViewController.h"
#import "ECSlidingViewController.h"

@implementation FDFeedNavigationViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FDMenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        [(FDMenuViewController *)self.slidingViewController.underLeftViewController refresh];
    }
    
    /*if (![self.slidingViewController.underRightViewController isKindOfClass:[FDFeedTypesViewController class]]) {
        self.slidingViewController.underRightViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"FeedTypes"];
    }*/
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

@end
