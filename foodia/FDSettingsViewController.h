//
//  FDSettingsViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDSettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UITextView *location;
@property (weak, nonatomic) IBOutlet UITextView *occupation;
-(IBAction)saveChanges;
@end
