//
//  FDEditProfileViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 3/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDEditProfileViewController.h"
#import "FDSlidingViewController.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"
#import "UIButton+WebCache.h"
#import "Utilities.h"
#import "Flurry.h"

@interface FDEditProfileViewController () <UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *userPhoto;
@property (weak, nonatomic) IBOutlet UILabel *photoPrompt;
@property (weak, nonatomic) IBOutlet UIButton *saveProfileButton;
-(void)loadDetails;
-(IBAction)submitDetails;
-(IBAction)editPhoto;
@end

@implementation FDEditProfileViewController
@synthesize user;
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
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logEvent:@"Editing profile"];
    [self loadDetails];
    self.userPhoto.imageView.layer.cornerRadius = 5.0f;
    [self.userPhoto.imageView setBackgroundColor:[UIColor clearColor]];
    [self.userPhoto.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.userPhoto.imageView.layer.shouldRasterize = YES;
    self.userPhoto.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.saveProfileButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.saveProfileButton.layer.shadowOffset = CGSizeMake(0,0);
    self.saveProfileButton.layer.shadowOpacity = .2;
    self.saveProfileButton.layer.shadowRadius = 3.0;
	// Do any additional setup after loading the view.
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.passwordTextField setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.nameTextField setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.locationTextField setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.saveProfileButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.passwordTextField setText:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]];
    if (self.userPhoto.imageView != nil) [self.photoPrompt setHidden:YES];
    if ([self.presentingViewController isKindOfClass:[FDLoginViewController class]]) {
        [self.passwordTextField setHidden:YES];
        [self.passwordBackground setHidden:YES];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -40);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.view endEditing:YES];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.locationTextField || textField == self.nameTextField || textField == self.passwordTextField) {
        [textField resignFirstResponder];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.view.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
    return NO;
}

- (void)loadDetails {
    [[FDAPIClient sharedClient] getProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] success:^(id result) {
        if ([[result objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
            [self.userPhoto setImageWithURL:[Utilities profileImageURLForFacebookID:[result objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
            [self.userPhoto setUserInteractionEnabled:NO];
            [self.userPhoto setEnabled:NO];
            [self.photoPrompt setHidden:YES];
        } else if ([result objectForKey:@"avatar_url"] != [NSNull null]) {
            NSLog(@"avatar: %@",[result objectForKey:@"avatar_url"]);
            [self.userPhoto setImageWithURL:[NSURL URLWithString:[result objectForKey:@"avatar_url"]] forState:UIControlStateNormal];
        }
        if ([result objectForKey:@"name"] != [NSNull null]){
            [self.nameTextField setText:[result objectForKey:@"name"]];
        }
        if ([result objectForKey:@"location"]  != [NSNull null]){
            [self.locationTextField setText:[result objectForKey:@"location"]];
        }
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } failure:^(NSError *error) {
       
    }];
}

- (IBAction)submitDetails {
    [self.view endEditing:YES];
    
    if (self.nameTextField.text.length > 0 && self.userPhoto.imageView.image != nil){
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        
        [[FDAPIClient sharedClient] updateProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]
                                                    name:self.nameTextField.text
                                                location:self.locationTextField.text
                                               userPhoto:self.userPhoto.imageView.image
                                                password:self.passwordTextField.text
                                                 success:^(FDUser *theUser) {
                                                     
            [[NSUserDefaults standardUserDefaults] setObject:theUser.authenticationToken forKey:kUserDefaultsAuthenticationToken];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.avatarUrl forKey:kUserDefaultsAvatarUrl];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.password forKey:kUserDefaultsPassword];
            
                                                     
            if ([self.presentingViewController isKindOfClass:[FDLoginViewController class]]){
                if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
                    UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
                    FDSlidingViewController *vc = [storyboard5 instantiateViewControllerWithIdentifier:@"SlidingView"];
                    [self presentViewController:vc animated:YES completion:nil];
                } else {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
                    FDSlidingViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"SlidingView"];
                    [self presentViewController:vc animated:YES completion:nil];
                }
            } else {
                NSLog(@"should be modally dismissing");
                [self dismissModalViewControllerAnimated:YES];
            }

        } failure:^(NSError *error) {
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've included all fields, including your password." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"error updating profile details: %@",error.description);
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've included your name as well as photo. Look sharp now." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (IBAction)editPhoto
{
    UIActionSheet *actionSheet = nil;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:self.userPhoto.imageView ? @"Remove Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:self.userPhoto.imageView ? @"Remove Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: //remove photo
            if (self.userPhoto.imageView)
                [self removePhoto];
            else {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self choosePhoto];
            }
            break;
        case 1:
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self choosePhoto];
            break;
        case 2:
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                [self takePhoto];
            break;
        case 3:
            [actionSheet dismissWithClickedButtonIndex:2 animated:YES];
        default:
            break;
    }
}

- (void)choosePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
    NSLog(@"should be taking photo");
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.userPhoto setImage:image forState:UIControlStateNormal];
}


-(void)removePhoto {
    [self.userPhoto setImage:nil forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
