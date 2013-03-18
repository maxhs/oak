//
//  FDEmailConnectViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 3/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDEmailConnectViewController.h"
#import "FDAPIClient.h"

@interface FDEmailConnectViewController ()
-(IBAction)signIn;
@end

@implementation FDEmailConnectViewController

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
	// Do any additional setup after loading the view.
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.view endEditing:YES];
}

- (IBAction)signIn {
    [[FDAPIClient sharedClient] setEmail:self.emailTextField.text];
    [[FDAPIClient sharedClient] setPassword:self.passwordTextField.text];
    [[FDAPIClient sharedClient] registerUser];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
