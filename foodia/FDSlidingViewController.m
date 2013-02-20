//
//  FDSlidingViewController.m
//  foodia
//
//  Created by Charles Mezak and Max Haines-Stiles on 7/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDSlidingViewController.h"
#import "FDAppDelegate.h"
#import "FDProfileNavigationController.h"
#import "FDProfileViewController.h"


@interface FDSlidingViewController ()

@end

@implementation FDSlidingViewController

@synthesize documentInteractionController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)showInstagram:(UIDocumentInteractionController *)ic
{
    self.documentInteractionController = ic;
    [self performSelector:@selector(showIg) withObject:nil afterDelay:2.0];
}
-(void)showIg {
    [self.documentInteractionController presentOpenInMenuFromRect:self.topViewController.view.frame inView:self.topViewController.view animated:true];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIStoryboard *storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0){
        storyboard = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedNavigation"];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedNavigation"];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
