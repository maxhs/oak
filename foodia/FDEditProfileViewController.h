//
//  FDEditProfileViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 3/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDUser.h"


@interface FDEditProfileViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *passwordBackground;
@property (strong, nonatomic) FDUser *user;
@end
