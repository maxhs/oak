//
//  FDWebViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 2/4/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDWebViewController.h"
#import "FDAppDelegate.h"

@interface FDWebViewController () <UIWebViewDelegate, UIAlertViewDelegate>
@end

@implementation FDWebViewController

@synthesize url;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURLRequest *requestObject = [NSURLRequest requestWithURL:url];
    NSLog(@"url: %@",url);
    NSLog(@"requestObject: %@",requestObject);
    [self.webView loadRequest:requestObject];
	// Do any additional setup after loading the view.
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView failed to load. Here's why: %@",error.description);
    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we were unable to load this website." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
