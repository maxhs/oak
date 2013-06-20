//
//  FDLoginViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAppDelegate.h"

@interface FDLoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *dummyStuff;
- (IBAction)login:(id)sender;
- (IBAction)showEmailConnect;
- (IBAction)cancelEmailConnect;
- (IBAction)forgotPassword;
- (void)loginFailed;

@end
