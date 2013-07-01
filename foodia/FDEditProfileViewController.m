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
#define kFoodPhilosophyPlaceholder @"Your food philosophy"

@interface FDEditProfileViewController () <UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UITextViewDelegate> {
    UIEdgeInsets originalInset;
}
@property (weak, nonatomic) IBOutlet UIButton *userPhoto;
@property (weak, nonatomic) IBOutlet UILabel *photoPrompt;
@property (weak, nonatomic) IBOutlet UIButton *saveProfileButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UITextView *philosophyTextView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
-(void)loadDetails;
-(IBAction)submitDetails;
-(IBAction)editPhoto;
-(IBAction)cancel;
-(IBAction)back;
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
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,180,44);
    navTitle.text = @"Edit my profile";
    navTitle.font = [UIFont fontWithName:kHelveticaNeueThin size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    UIImageView *backgroundView = [[UIImageView alloc] init];
    [backgroundView setBackgroundColor:[UIColor whiteColor]];
    self.tableView.backgroundView = backgroundView;
    
    [self loadDetails];
    self.userPhoto.imageView.layer.cornerRadius = 5.0f;
    [self.userPhoto.imageView setBackgroundColor:[UIColor clearColor]];
    [self.userPhoto.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.userPhoto.imageView.layer.shouldRasterize = YES;
    self.userPhoto.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.philosophyTextView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.4].CGColor;
    self.philosophyTextView.layer.borderWidth = .5f;
    self.philosophyTextView.layer.cornerRadius = 5.0f;
    self.philosophyTextView.clipsToBounds = YES;

    self.saveProfileButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.saveProfileButton.layer.shadowOffset = CGSizeMake(0,0);
    self.saveProfileButton.layer.shadowOpacity = .2;
    self.saveProfileButton.layer.shadowRadius = 3.0;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
        [self.passwordBackground setHidden:YES];
        [self.passwordTextField setHidden:YES];
        [self.userPhoto setEnabled:NO];
        [self.nameTextField setEnabled:NO];
        [self.nameTextField setTextColor:[UIColor lightGrayColor]];
    }

    originalInset = self.tableView.contentInset;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.passwordTextField setText:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]];
    if (self.userPhoto.imageView != nil) [self.photoPrompt setHidden:YES];
    if ([self.presentingViewController isKindOfClass:[FDLoginViewController class]]) {
        [self.passwordTextField setHidden:YES];
        [self.passwordBackground setHidden:YES];
        [self.navBar setHidden:YES];
        self.cancelButton = nil;
    }
}

#pragma mark - TableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)willShowKeyboard:(NSNotification *)notification {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(willHideKeyboard)];
    [cancelButton setTitle:kCancel];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    if ([UIScreen mainScreen].bounds.size.height == 568){
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+185.0, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+105.0, 0.0);
    }
    [UIView animateWithDuration:.25 animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    } completion:^(BOOL finished) {
        
    }];
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (self.passwordTextField.isFirstResponder){
        if (!CGRectContainsPoint(aRect, self.passwordTextField.frame.origin) ) {
            CGPoint scrollPoint = CGPointMake(0.0, 160.0);
            [self.tableView setContentOffset:scrollPoint animated:YES];
        }
    }
}

- (void)willHideKeyboard {
    [self.tableView setScrollEnabled:YES];
    [UIView animateWithDuration:.25 animations:^{
        [self.tableView setContentOffset:CGPointZero];
    } completion:^(BOOL finished) {
        self.tableView.contentInset = originalInset;
    }];
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

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kFoodPhilosophyPlaceholder]){
        [textView setTextColor:[UIColor blackColor]];
        [textView setText:@""];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0){
        [textView setTextColor:[UIColor lightGrayColor]];
        [textView setText:kFoodPhilosophyPlaceholder];
    }
}

- (void)loadDetails {
    [[FDAPIClient sharedClient] getProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] success:^(id result) {
        if ([[result objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
            [self.userPhoto setImageWithURL:[Utilities profileImageURLForFacebookID:[result objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
            [self.userPhoto setEnabled:NO];
            [self.photoPrompt setHidden:YES];
        } else if ([result objectForKey:@"avatar_url"] != [NSNull null]) {
            [self.userPhoto setImageWithURL:[NSURL URLWithString:[result objectForKey:@"avatar_url"]] forState:UIControlStateNormal];
        }
        if ([result objectForKey:@"name"] != [NSNull null]){
            [self.nameTextField setText:[result objectForKey:@"name"]];
        }
        if ([result objectForKey:@"location"]  != [NSNull null]){
            [self.locationTextField setText:[result objectForKey:@"location"]];
        }
        if ([[result objectForKey:@"philosophy"] length]){
            [self.philosophyTextView setText:[result objectForKey:@"philosophy"]];
            [self.philosophyTextView setTextColor:[UIColor blackColor]];
        }
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } failure:^(NSError *error) {
       
    }];
}

- (IBAction)submitDetails {
    [self.view endEditing:YES];
    NSString *philosophy;
    if ([self.philosophyTextView.text isEqualToString:kFoodPhilosophyPlaceholder]){
        philosophy = @"";
    } else {
        philosophy = self.philosophyTextView.text;
    }
    if (self.nameTextField.text.length > 0 && self.userPhoto.imageView.image != nil){
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        
        [[FDAPIClient sharedClient] updateProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]
                                                    name:self.nameTextField.text
                                                location:self.locationTextField.text
                                               userPhoto:self.userPhoto.imageView.image
                                              philosophy:philosophy
                                                password:self.passwordTextField.text
                                                 success:^(FDUser *theUser) {
                                                     
            [[NSUserDefaults standardUserDefaults] setObject:theUser.authenticationToken forKey:kUserDefaultsAuthenticationToken];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.avatarUrl forKey:kUserDefaultsAvatarUrl];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.password forKey:kUserDefaultsPassword];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.name forKey:kUserDefaultsUserName];
            [[NSUserDefaults standardUserDefaults] setObject:theUser.email forKey:kUserDefaultsEmail];
                                                     
            if ([self.presentingViewController isKindOfClass:[FDLoginViewController class]]){
                [self dismissViewControllerAnimated:YES completion:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginNewEmailUser" object:nil];
                }];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshPhilosophy" object:nil];
                [self dismissViewControllerAnimated:YES completion:^{
                    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
                }];
            }
            
        } failure:^(NSError *error) {
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've included all fields, including your password." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"error updating profile details: %@",error.description);
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Please make sure you've included your name as well as a photo. Look sharp now." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
        default:
            [actionSheet dismissWithClickedButtonIndex:2 animated:YES];
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
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.userPhoto setImage:image forState:UIControlStateNormal];
}


-(void)removePhoto {
    [self.userPhoto setImage:nil forState:UIControlStateNormal];
}

-(IBAction)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
