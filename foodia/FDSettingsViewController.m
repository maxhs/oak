//
//  FDSettingsViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/4/12.
//  Copyright (c) 2012 FOODIA Inc. All rights reserved.
//

#import "FDSettingsViewController.h"
#import "ECSlidingViewController.h"
#import "FDMenuViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Utilities.h"
#import "UIImageView+AFNetworking.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"

@interface FDSettingsViewController () <UITextViewDelegate>

@property (strong, nonatomic) AFJSONRequestOperation *profileDetailsRequest;
- (IBAction)revealMenu:(UIBarButtonItem *)sender;

@end

@implementation FDSettingsViewController
@synthesize profileDetailsRequest;
- (void)viewDidLoad
{
    [super viewDidLoad];
    //[(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,190,40);
    navTitle.text = @"SETTINGS";
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:24];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor whiteColor];
    navTitle.textAlignment = UITextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
    // Shift the title down a bit...
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:-1 forBarMetrics:UIBarMetricsDefault];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.profileDetailsRequest = [[FDAPIClient sharedClient] getProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookID"] success:^(NSDictionary *result) {
        self.location = [result objectForKey:@"location"];
    } failure:^(NSError *error) {
        NSLog(@"couldn't load profile details for settings screen");
    }];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[FDMenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount     = 0;
    self.slidingViewController.anchorLeftRevealAmount   = 0;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = 5.0f;
    [self.profileImageView setImageWithURL:[Utilities profileImageURLForCurrentUser]];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
}

- (IBAction)saveChanges {
    NSLog(@"please save changes");
}

#pragma mark -

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

@end
