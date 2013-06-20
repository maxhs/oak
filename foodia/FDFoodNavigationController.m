//
//  FDFoodNavigationController.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDFoodNavigationController.h"
#import "FDSlidingViewController.h"
#import "FDMenuViewController.h"

@interface FDFoodNavigationController ()

@end

@implementation FDFoodNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
