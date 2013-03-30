//
//  FDEmailConnectViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 3/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDUser.h"


@interface FDEmailConnectViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (strong, nonatomic) FDUser *user;
@end
