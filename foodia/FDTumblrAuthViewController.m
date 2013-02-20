//
//  FDTumblrAuthViewController.m
//  foodia
//
//  Created by Charles Mezak on 7/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDTumblrAuthViewController.h"
#import "FDTumblrAPIClient.h"

@interface FDTumblrAuthViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIImageView *tumblrLogo;
- (IBAction)cancel:(UIBarButtonItem *)sender;

@end

@implementation FDTumblrAuthViewController
@synthesize emailField;
@synthesize passwordField;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setEmailField:nil];
    [self setPasswordField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)validate {
    FDTumblrAPIClient *client = [FDTumblrAPIClient sharedClient];
    [client validateEmail:self.emailField.text
                 password:self.passwordField.text
                  success:NULL
                  failure:NULL];
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else {
        if (self.emailField.text.length)
            [self validate];
        else
            [self.emailField becomeFirstResponder];
    }
    return NO;
}

@end
