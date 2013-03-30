//
//  FDEmailConnectViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 3/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDEmailConnectViewController.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"

@interface FDEmailConnectViewController () <UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *userPhoto;
@property (weak, nonatomic) IBOutlet UILabel *photoPrompt;
-(IBAction)submitDetails;
-(IBAction)editPhoto;
@end

@implementation FDEmailConnectViewController
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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.userPhoto.imageView != nil) [self.photoPrompt setHidden:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.locationTextField || textField == self.nameTextField) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (IBAction)submitDetails {

    if (self.nameTextField.text.length > 0 && self.userPhoto.imageView){
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [[FDAPIClient sharedClient] updateProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] name:self.nameTextField.text location:self.locationTextField.text userPhoto:self.userPhoto.imageView.image success:^(FDUser *theUser) {
            [[NSUserDefaults standardUserDefaults] setObject:theUser.authenticationToken forKey:kUserDefaultsAuthenticationToken];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.avatarUrl forKey:kUserDefaultsAvatarUrl];
            [self performSegueWithIdentifier:@"SignUp" sender:self];
        } failure:^(NSError *error) {
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            NSLog(@"error updating profile details: %@",error.description);
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've included your name as well a photo. Look sharp now." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
        case 1: // new photo
            if (self.userPhoto.imageView) {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self choosePhoto];
            } else {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                    [self takePhoto];
            }
            break;
        case 2:
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
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.userPhoto setImage:image forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:nil];
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
