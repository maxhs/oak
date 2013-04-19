//
//  FDNewPostViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 11/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDNewPostViewController.h"
#import "FDPostCategoryViewController.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDAPIClient.h"
#import <CoreLocation/CoreLocation.h>
#import "Utilities.h"
#import "FDVenue.h"
#import "FDFoursquareAPIClient.h"
#import "FDTagFriendsViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>
#import "FDPostViewController.h"
#import "Constants.h"
#import "FDProfileViewController.h"
#import "Flurry.h" 
#import "FDFeedNavigationViewController.h"
#import "UIButton+WebCache.h"
#import "GPUImage.h"
#import "FDCameraViewController.h"

NSString *const kPlaceholderAddPostCommentPrompt = @"I'M THINKING...";

@interface FDNewPostViewController () <UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *friendsButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UIButton *foodiaObjectButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *addPhotoLabel;
@property (weak, nonatomic) IBOutlet UILabel *foodiaObjectLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak,nonatomic) NSString *postReturnURL;
@property (nonatomic, readwrite, retain) UIWebView *webView;
@property (strong, atomic) ALAssetsLibrary *library;
@property UIImageOrientation *imageOrientationWhenAddedToScreen;
@property (strong, nonatomic) UIScrollView *filterScrollView;
@property (strong, nonatomic) GPUImageFilter *selectedFilter;
@property (strong, nonatomic) NSArray *filterArray;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIButton *cameraButton;
@property (strong, nonatomic) UIImage *capturedScreen;
@property (strong, nonatomic) UIImageView *filteredImageView;
@property (strong, nonatomic) UIButton *cancelButton;
@property BOOL isEditing;

- (IBAction)editPhoto:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)submitPost:(id)sender;
- (IBAction)editCategory:(id)sender;

@end

@implementation FDNewPostViewController

@synthesize documentInteractionController = _documentInteractionController;
@synthesize locationLabel = _locationLabel;
@synthesize foodiaObjectLabel = _foodiaObjectLabel;
@synthesize foursquareButton, instagramButton, twitterButton;
@synthesize postReturnURL;
@synthesize webView = _webView;
@synthesize library;
@synthesize imageOrientationWhenAddedToScreen;
@synthesize isEditing = _isEditing;
@synthesize selectedFilter = _selectedFilter;
@synthesize filteredImageView;

static NSDictionary *categoryImages = nil;

+ (void)initialize {
    categoryImages = @{
    @"Making" : [UIImage imageNamed:@"newPostPlaceholderMaking.jpeg"],
    @"Eating" : [UIImage imageNamed:@"newPostPlaceholderEating.jpeg"],
    @"Drinking" : [UIImage imageNamed:@"newPostPlaceholderDrinking.jpeg"],
    @"Shopping" : [UIImage imageNamed:@"newPostPlaceholderShopping.jpeg"]
    };
}

+ (UIImage *)imageForCategory:(NSString *)category {
    return [categoryImages objectForKey:category];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Add post menu" timed:YES];
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"SAVE"]){
        self.isEditing = YES;
        [self.deleteButton setHidden:NO];
        [self.facebookButton setHidden:YES];
        [self.foursquareButton setHidden:YES];
        [self.twitterButton setHidden:YES];
        [self.instagramButton setHidden:YES];
    } else {
        self.isEditing = NO;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"POST" style:UIBarButtonItemStyleBordered target:nil action:nil];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
            [self.navigationItem.backBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:kFuturaMedium size:16], UITextAttributeTextColor:[UIColor blackColor]} forState:UIControlStateNormal];
        }
    }
    
    self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoButton.imageView.clipsToBounds = YES;
    [self updateCrossPostButtons];
    self.posterImageView.layer.cornerRadius = 22.0f;
    self.posterImageView.clipsToBounds = YES;
    self.posterImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.posterImageView.layer.borderWidth = .5f;
    [self.posterImageView setImageWithURL:[Utilities profileImageURLForCurrentUser]];

    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.delegate = self;

    //always toggle foursquare sharing off to start
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:kDefaultsFoursquareActive];
    [self updateCrossPostButtons];
    self.library = [[ALAssetsLibrary alloc]init];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.locationButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.friendsButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.foodiaObjectButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.recButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.captionTextView setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.addPhotoLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.locationLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.foodiaObjectLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.deleteButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:kFuturaMedium size:16], UITextAttributeTextColor:[UIColor blackColor]} forState:UIControlStateNormal];
        [self.navigationController.navigationItem.backBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:kFuturaMedium size:16], UITextAttributeTextColor:[UIColor blackColor]} forState:UIControlStateNormal];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (FDPost.userPost.locationName) {
        [self venueChosen];
        /*[self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView addAnnotation:FDPost.userPost];
        [self.mapView setRegion:MKCoordinateRegionMake(FDPost.userPost.coordinate, MKCoordinateSpanMake(0.002, 0.002))];*/
    } else if (FDPost.userPost.location == nil) {
        [self.locationManager startUpdatingLocation];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken] && [[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.facebookButton setHidden:YES];
        self.twitterButton.transform = CGAffineTransformMakeTranslation(-29, 0);
        self.instagramButton.transform = CGAffineTransformMakeTranslation(-29, 0);
        self.foursquareButton.transform = CGAffineTransformMakeTranslation(-29, 0);
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self showPostInfo];
}

/*- (void)findingLocation {
    self.confirmLocationImageView.hidden = YES;
    [self.noLocationActivityIndicatorView startAnimating];
}

- (void)locationFound {
    self.locationContainerView.hidden = YES;
    [self.noLocationActivityIndicatorView stopAnimating];
    self.confirmLocationImageView.hidden = NO;
}

- (void)locationFailed {
    self.locationContainerView.hidden = YES;
    [self.noLocationActivityIndicatorView stopAnimating];
}
*/
- (void)venueChosen {
    //self.locationContainerView.hidden = NO;
    self.locationLabel.text = [FDPost.userPost.locationName uppercaseString];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowProfileFromNewPost"]){
        FDProfileViewController *vc = [segue destinationViewController];
        UIButton *button = (UIButton *)sender;
        [vc initWithUserId:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"editCategory"]) {
        FDPostCategoryViewController *vc = [segue destinationViewController];
        [vc setIsEditing:YES];
        [vc setThePost:FDPost.userPost];
    }
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //[self locationFailed];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
        //[self locationFound];
        FDPost.userPost.location = location;
        [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:NULL failure:NULL];
        [manager stopUpdatingLocation];

}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        //[self locationFound];
        FDPost.userPost.location = newLocation;
        [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:newLocation success:NULL failure:NULL];
        [manager stopUpdatingLocation];

}

#pragma mark - Private Methods

- (void)showPostInfo
{
    self.post = FDPost.userPost;
    if (FDPost.userPost.caption.length > 0){
        self.captionTextView.text = FDPost.userPost.caption;
    } else {
        self.captionTextView.text = kPlaceholderAddPostCommentPrompt;
    }
    self.captionTextView.layer.borderWidth = .5f;
    self.captionTextView.layer.cornerRadius = 5.0f;
    self.captionTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.captionTextView.contentInset = UIEdgeInsetsMake(-2,-3,0,0);
    self.captionTextView.textAlignment = NSTextAlignmentLeft;
    if (FDPost.userPost.photoImage){
        [self.photoButton setImage:FDPost.userPost.photoImage forState:UIControlStateNormal];
        [self.photoBackgroundView setAlpha:1.0];
    } else {
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setImageWithURL:self.post.detailImageURL];
        [self.photoButton setImage:imageView.image forState:UIControlStateNormal];
        self.post.photoImage = imageView.image;
    }
    if (self.photoButton.imageView.image) [self.photoBackgroundView setAlpha:1.0];
    
    //self.photoButton.hidden = !self.post.photoImage;
    [self.foodiaObjectButton setTitle:[NSString stringWithFormat:@"I'M %@", self.post.category.uppercaseString] forState:UIControlStateNormal];
    //self.categoryImageView.image = [FDNewPostViewController imageForCategory:self.post.category];
    
    //location section
    if (FDPost.userPost.locationName.length > 0){
        [self rearrangeButton:self.locationButton andView:self.locationLabel];
    } else {
        [self disArrangeButton:self.locationButton andView:self.locationLabel];
    }
    
    //food object section
    if (self.post.foodiaObject.length > 0){
        self.foodiaObjectLabel.text = self.post.foodiaObject.uppercaseString;
        [self rearrangeButton:self.foodiaObjectButton andView:self.foodiaObjectLabel];
    } else {
        self.foodiaObjectLabel.text = FDPost.userPost.foodiaObject.uppercaseString;
        [self disArrangeButton:self.foodiaObjectButton andView:self.foodiaObjectLabel];
    }
    
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;
    
    //social tagging section
    if (self.post.withFriends.count > 0){
        [self rearrangeButton:self.friendsButton andView:self.friendsScrollView];
        [self.friendsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.friendsScrollView.showsHorizontalScrollIndicator=NO;
        
        for (FDUser *friend in [FDPost.userPost.withFriends allObjects]) {
            UIButton *friendButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [friendButton setFrame:CGRectMake(((space+imageSize)*index),0,imageSize, imageSize)];
            [friendButton addTarget:self action:@selector(profileTappedFromNewPost:) forControlEvents:UIControlEventTouchUpInside];
            [friendButton setAlpha:0.0];
            
            if (friend.fbid.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [friendButton setImageWithURL:[Utilities profileImageURLForFacebookID:friend.fbid] forState:UIControlStateNormal];
                friendButton.titleLabel.text = friend.fbid;
                [self animateOn:friendButton];
            } else if (friend.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [friendButton setImageWithURL:[Utilities profileImageURLForFacebookID:friend.facebookId] forState:UIControlStateNormal];
                friendButton.titleLabel.text = friend.facebookId;
                [self animateOn:friendButton];
            } else {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",friend.userId]];
                [friendButton setImageWithURL:url forState:UIControlStateNormal];
                
                /*[[FDAPIClient sharedClient] getProfilePic:friend.userId success:^(NSURL *url) {
                    [friendButton setImageWithURL:url forState:UIControlStateNormal];
                    [self animateOn:friendButton];
                    [[SDImageCache sharedImageCache] storeImage:friendButton.imageView.image forKey:friend.userId];
                } failure:^(NSError *error) {}];*/
                friendButton.titleLabel.text = friend.userId;
            }
            friendButton.titleLabel.hidden = YES;
            friendButton.imageView.layer.cornerRadius = 17.0;
            [friendButton.imageView setBackgroundColor:[UIColor clearColor]];
            [friendButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
            friendButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            friendButton.imageView.layer.shouldRasterize = YES;
            
            [self.friendsScrollView addSubview:friendButton];
            index++;
        }
        [self.friendsScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),34)];
    }
    
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"POST"]) {
        //recommend section
        int index2 = 0;
        
        if (self.post.recommendedTo.count > 0){
            [self rearrangeButton:self.recButton andView:self.recScrollView];
            [self.recScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            self.recScrollView.showsHorizontalScrollIndicator=NO;
            
            for (FDUser *recipient in [FDPost.userPost.recommendedTo allObjects]) {
                UIButton *recommendeeButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [recommendeeButton setFrame:CGRectMake(((space+imageSize)*index2),0,imageSize, imageSize)];

                [recommendeeButton addTarget:self action:@selector(profileTappedFromNewPost:) forControlEvents:UIControlEventTouchUpInside];
                [recommendeeButton setAlpha:0.0];
                
                if (recipient.fbid.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
                    [recommendeeButton setImageWithURL:[Utilities profileImageURLForFacebookID:recipient.fbid] forState:UIControlStateNormal];
                    [self animateOn:recommendeeButton];
                    recommendeeButton.titleLabel.text = recipient.fbid;
                } else if (recipient.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
                    [recommendeeButton setImageWithURL:[Utilities profileImageURLForFacebookID:recipient.facebookId] forState:UIControlStateNormal];
                    [self animateOn:recommendeeButton];
                    recommendeeButton.titleLabel.text = recipient.facebookId;
                } else {
                    [[FDAPIClient sharedClient] getProfilePic:recipient.userId success:^(NSURL *url) {
                        [recommendeeButton setImageWithURL:url forState:UIControlStateNormal];
                        [self animateOn:recommendeeButton];
                    } failure:^(NSError *error) {}];
                    recommendeeButton.titleLabel.text = recipient.userId;
                }
                recommendeeButton.titleLabel.hidden = YES;
                
                recommendeeButton.imageView.layer.cornerRadius = 17.0;
                [recommendeeButton.imageView setBackgroundColor:[UIColor clearColor]];
                [recommendeeButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
                recommendeeButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                recommendeeButton.imageView.layer.shouldRasterize = YES;

                [self.recScrollView addSubview:recommendeeButton];
                index2++;
            }
            [self.recScrollView setContentSize:CGSizeMake(((space*(index2+1))+(imageSize*(index2+1))),34)];
        }
        
    } else [self.recButton setHidden:YES];
}

-(void)animateOn:(UIButton*)button{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [button setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)rearrangeButton:(UIButton*)button andView:(UIView*)view  {
    
    [UIView animateWithDuration:.3 delay:.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [button setFrame:CGRectMake(4,button.frame.origin.y,button.frame.size.width, button.frame.size.height)];
        [view setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)disArrangeButton:(UIButton*)button andView:(UIView*)view  {
    [UIView animateWithDuration:.3 delay:.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [button setFrame:CGRectMake(100,button.frame.origin.y,button.frame.size.width, button.frame.size.height)];
        [view setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - UITextViewDelegate Methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    return YES;
}


- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderAddPostCommentPrompt]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [textView resignFirstResponder];
    //self.navigationItem.rightBarButtonItem = nil;
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        textView.text = kPlaceholderAddPostCommentPrompt;
        textView.textColor = [UIColor lightGrayColor];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            textView.font = [UIFont fontWithName:kAvenirMedium size:16];
        } else {
            textView.font = [UIFont fontWithName:kFuturaMedium size:16];
        }
        
    } else {
        FDPost.userPost.caption = textView.text;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        FDPost.userPost.caption = self.captionTextView.text;
        [self.captionTextView resignFirstResponder];
        [self.captionTextView setContentOffset:CGPointZero animated:YES];
        return NO;
    }
    
    return YES;
}

- (IBAction)editPhoto:(id)sender
{
    UIActionSheet *actionSheet = nil;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:[FDPost.userPost photoImage] ? @"Remove Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:[FDPost.userPost photoImage] ? @"Remove Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: //remove photo
            if ([FDPost.userPost photoImage])
                [self removePhoto];
            else {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self choosePhoto];
            }
            break;
        case 1: // new photo
            if ([FDPost.userPost photoImage]) {
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
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setDelegate:self];
    [picker setAllowsEditing:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)takePhoto {
    /*self.picker = [[UIImagePickerController alloc] init];
    
    [self.picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self.picker setDelegate:self];
    [self.picker setAllowsEditing:YES];
    
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraButton setBackgroundImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(capturePhoto) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton addTarget:self action:@selector(imagePickerControllerDidCancel:) forControlEvents:UIControlEventTouchUpInside];
    
    //set up filters
    GPUImageFilter *amatorkaFilter = [[GPUImageBrightFilter alloc] init];
    GPUImageFilter *missFilter = [[GPUImageMeyerFilter alloc] init];
    GPUImageFilter *tiltFilter = [[GPUImageTiltShiftFilter alloc] init];
    GPUImageFilter *fadeFilter = [[GPUImageVignetteFilter alloc] init];
    GPUImageFilter *softEleganceFilter = [[GPUImageSoftEleganceFilter alloc] init];
    GPUImageFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    //GPUImageFilter *toonFilter = [[GPUImageToonFilter alloc] init];
    GPUImageFilter *openingFilter = [[GPUImageOpeningFilter alloc] init];
    //GPUImageFilter *sketchFilter = [[GPUImageSketchFilter alloc] init];
    GPUImageFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];

    self.filterArray = [NSArray arrayWithObjects:amatorkaFilter, missFilter, tiltFilter, fadeFilter, softEleganceFilter, sepiaFilter, openingFilter, grayscaleFilter, nil];
    
    self.filterScrollView = [[UIScrollView alloc] init];
    [self.filterScrollView addSubview:self.cameraButton];
    [self.filterScrollView addSubview:self.cancelButton];
    
    if ([UIScreen mainScreen].bounds.size.height == 568){
        [self.filterScrollView setFrame:CGRectMake(0, 568, 320, 96)];
        [self.cameraButton setFrame:CGRectMake(116, 8,80,80)];
        [self.cancelButton setFrame:CGRectMake(20,32,62,36)];
    } else {
        [self.filterScrollView setFrame:CGRectMake(0, 480, 320, 96)];
        [self.cameraButton setFrame:CGRectMake(134, 0,50,50)];
        [self.cancelButton setFrame:CGRectMake(12,10,58,30)];
    }
    [self.filterScrollView setContentSize:CGSizeMake((self.filterArray.count*66 + 66)-6,76)];
    [self.filterScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"customPhotoButtonBackground"]]];
    self.filterScrollView.showsHorizontalScrollIndicator = NO;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"customPhotoButtonBackground"] forState:UIControlStateNormal];
    self.cancelButton.layer.cornerRadius = 9.f;
    self.cancelButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.clipsToBounds = YES;
    [self.cancelButton.titleLabel setFont:[UIFont fontWithName:kAvenirDemiBold size:14]];
    [self.view.window addSubview:self.filterScrollView];
    [UIView animateWithDuration:.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([UIScreen mainScreen].bounds.size.height == 568){
            self.filterScrollView.transform = CGAffineTransformMakeTranslation(0, -95);
        } else {
            self.filterScrollView.transform = CGAffineTransformMakeTranslation(0, -51);
            
        }
    } completion:^(BOOL finished) {
        
    }];
    [self presentViewController:self.picker animated:YES completion:nil];*/
    [self performSegueWithIdentifier:@"TakePhoto" sender:self];
    
}

- (void)capturePhoto{
    [self.picker takePicture];
    [self.cancelButton setHidden:YES];
    [self.cameraButton setHidden:YES];
    [self setUpFilters];
}

- (void)setUpFilters {
    UIView *noneButtonView = [self addFilter:nil withIndex:0];
    [self.filterScrollView addSubview:noneButtonView];
    int index = 1;
    for (GPUImageFilter *filter in self.filterArray){
        UIView *filterButtonView = [self addFilter:filter withIndex:index];
        [self.filterScrollView addSubview:filterButtonView];
        index ++;
    }
    [UIView animateWithDuration:.25 delay:.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([UIScreen mainScreen].bounds.size.height == 568){
            [self.filterScrollView setFrame:CGRectMake(0, 396, 320, 82)];
            [self.view.window addSubview:self.cancelButton];
            [self.cancelButton setBounds:CGRectMake(20,400,60,34)];
        } else {
            [self.filterScrollView setFrame:CGRectMake(0, 374, 320, 60)];
            [self.filterScrollView setContentSize:CGSizeMake((self.filterArray.count*66 + 66)-6,60)];
            
        }
    } completion:^(BOOL finished){
        int index = 0;
        [self.filterScrollView setBackgroundColor:[UIColor colorWithWhite:.21 alpha:1]];
        for (UIView *view in self.filterScrollView.subviews) {
            [UIView animateWithDuration:.1 delay:.05*index options:UIViewAnimationOptionCurveEaseInOut animations:^{
                view.transform = CGAffineTransformMakeTranslation(0, -100);
            } completion:^(BOOL finished) {
            }];
            index ++;
            
        }
        UIGraphicsBeginImageContextWithOptions(self.picker.view.layer.frame.size,NO, 0.0f);
        [self.picker.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        self.capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [super dismissViewControllerAnimated:YES completion:nil];
    
    [UIView animateWithDuration:.15 animations:^{
        [self.filterScrollView setAlpha:0.0];
        self.filteredImageView.transform = CGAffineTransformMakeTranslation(0, 600);
    } completion:^(BOOL finished) {
        [self.filterScrollView removeFromSuperview];
        [self.filteredImageView removeFromSuperview];
        self.filteredImageView = nil;
    }];
}

- (UIView*)addFilter:(GPUImageFilter*)filter withIndex:(int)x {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x*66, 100, 70, 70)];
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [filterButton setBackgroundImage:[filter imageByFilteringImage:[UIImage imageNamed:@"grapes.jpg"]] forState:UIControlStateNormal];

    filterButton.layer.borderWidth = 1.0;
    filterButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    filterButton.layer.shouldRasterize = YES;
    filterButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    UILabel *filterLabel = [[UILabel alloc] init];
    [filterLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
    [filterLabel setBackgroundColor:[UIColor clearColor]];
    [filterLabel setTextColor:[UIColor whiteColor]];
    [filterLabel setTextAlignment:NSTextAlignmentCenter];
    
    [view addSubview:filterButton];
    [view addSubview:filterLabel];
    if ([UIScreen mainScreen].bounds.size.height == 568){
        [filterLabel setFrame:CGRectMake(0,64,60,18)];
        [filterButton setFrame:CGRectMake(0,3,60,60)];
    } else {
        [filterLabel setFrame:CGRectMake(0,46,60,18)];
        [filterButton setFrame:CGRectMake(0,0,60,60)];
    }
    
    switch (x) {
        case 0:
            [filterLabel setText:@"NONE"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"grapes.jpg"] forState:UIControlStateNormal];
            break;
        case 1:
            [filterLabel setText:@"MEYER"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"meyer.jpg"] forState:UIControlStateNormal];
            break;
        case 2:
            [filterLabel setText:@"PASTEL"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"pastel.jpg"] forState:UIControlStateNormal];
            break;
        case 3:
            [filterLabel setText:@"TILT"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"tilt.jpg"] forState:UIControlStateNormal];
            break;
        case 4:
            [filterLabel setText:@"FADE"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"fade.jpg"] forState:UIControlStateNormal];
            break;
        case 5:
            [filterLabel setText:@"SOFT"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"meyer.jpg"] forState:UIControlStateNormal];
            break;
        case 6:
            [filterLabel setText:@"HONEY"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"honey.jpg"] forState:UIControlStateNormal];
            break;
        /*case 7:
            [filterLabel setText:@"JELLO"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"jello.jpg"] forState:UIControlStateNormal];
            break;*/
        case 7:
            [filterLabel setText:@"OIL"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"oil.jpg"] forState:UIControlStateNormal];
            break;
        /*case 9:
            [filterLabel setText:@"FOAM"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"foam.jpg"] forState:UIControlStateNormal];
            break;*/
        case 8:
            [filterLabel setText:@"B&W"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"b&w.jpg"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    filterButton.imageView.layer.cornerRadius = 3.0;
    [filterButton.imageView setBackgroundColor:[UIColor clearColor]];
    [filterButton.imageView.layer setBackgroundColor:[UIColor colorWithWhite:.21 alpha:1].CGColor];
    [filterButton addTarget:self action:@selector(selectFilter:) forControlEvents:UIControlEventTouchUpInside];
    [filterButton setTag:x];
    [filterButton.titleLabel setHidden:YES];
    

    return view;
}

- (void) selectFilter:(id)sender {
    UIButton *button = (UIButton *) sender;
    for (UIView *view in self.filterScrollView.subviews){
        for (UIButton *button in view.subviews)
            if ([button isKindOfClass:[UIButton class]]){
                button.layer.shadowColor = [UIColor clearColor].CGColor;
                button.layer.shadowOffset = CGSizeMake(0,0);
                button.layer.shadowOpacity = 0.0;
                button.layer.shadowRadius = 0.0;
            }
    }
    button.layer.shadowColor = [UIColor whiteColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0,3);
    button.layer.shadowOpacity = 5.0;
    button.layer.shadowRadius = 7.5;
    int index = button.tag-1;
    if (index < 0){
        self.selectedFilter = nil;
    } else {
        self.selectedFilter = [self.filterArray objectAtIndex:index];
        NSLog(@"selected filter: %@",self.selectedFilter);
    }
    
    CGRect rect;
    if ([UIScreen mainScreen].bounds.size.height == 568){
        rect = CGRectMake(0,152,640,640);
    } else {
        rect = CGRectMake(0,108,640,640);
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect([self.capturedScreen CGImage], rect);
    if (self.filteredImageView == nil){
        self.filteredImageView = [[UIImageView alloc] initWithImage:[self.selectedFilter imageByFilteringImage:[UIImage imageWithCGImage:imageRef]]];
    } else {
        //[self.filteredImageView setImage:[self.selectedFilter imageByFilteringImage:[UIImage imageWithCGImage:imageRef]]];
        [self.filteredImageView setImage:[self.selectedFilter imageByFilteringImage:[UIImage imageNamed:@"grapes.jpg"]]];
    }
    if ([UIScreen mainScreen].bounds.size.height == 568){
        [self.filteredImageView setFrame:CGRectMake(0, 76, 320, 320)];
    } else  {
        [self.filteredImageView setFrame:CGRectMake(0, 54, 320, 320)];
    }
    [self.picker.view.window addSubview:self.filteredImageView];
}

/*- (void)loadTumblrApi {
    oauthTumblrAppViewController *vc = [[oauthTumblrAppViewController alloc] init];
    [self presentModalViewController:vc animated:YES];
}*/

#pragma mark - Private
-(void)removePhoto {
    [UIView animateWithDuration:0.25 animations:^{
        CGAffineTransform shrinkTransform = CGAffineTransformMakeScale(0.001, 0.001);
        self.photoBackgroundView.transform = shrinkTransform;
        self.photoButton.transform = shrinkTransform;
        self.photoBackgroundView.alpha = 0.0;
        self.photoButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        FDPost.userPost.photoImage = nil;
        [self.post setDetailImageUrlString:nil];
        [self showPostInfo];
        self.photoButton.transform = CGAffineTransformIdentity;
        self.photoBackgroundView.transform = CGAffineTransformIdentity;
        self.photoBackgroundView.alpha = 0.0;
        self.photoButton.alpha = 1.0;
    }];
}

- (IBAction)addPhoto:(id)sender {
    [[FDPost userPost] setCaption:self.captionTextView.text];
    [self editPhoto:nil];
}

#pragma mark - cross post buttons

- (IBAction)toggleInstagram:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]
                                            forKey:kDefaultsInstagramActive];
    [self updateCrossPostButtons];
}

- (IBAction)toggleTwitter:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]
                                            forKey:kDefaultsTwitterActive];
    [self updateCrossPostButtons];
}

- (IBAction)toggleFoursquare:(id)sender {
    if (FDPost.userPost.locationName){
        [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]
                                            forKey:kDefaultsFoursquareActive];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]) {
            [self foursquareWebview];
        }
        [self updateCrossPostButtons];
    } else {
        [[[UIAlertView alloc]initWithTitle:@"Uh-oh..." message:@"We don't know where you are! Please provide a location before checking in." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
    }
}


- (IBAction)toggleFacebook {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFacebookActive] forKey:kDefaultsFacebookActive];
        [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"] forKey:@"OpenGraph"];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]) [(FDAppDelegate *)[UIApplication sharedApplication].delegate getPublishPermissions];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFacebookActive] forKey:kDefaultsFacebookActive];
    }
    [self updateCrossPostButtons];
}

- (void)updateCrossPostButtons {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]) {
        [self.twitterButton setImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    } else {
        [self.twitterButton setImage:[UIImage imageNamed:@"twitterGray.png"] forState:UIControlStateNormal];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]) {
        [self.foursquareButton setImage:[UIImage imageNamed:@"foursquare.png"] forState:UIControlStateNormal];
    } else {
        [self.foursquareButton setImage:[UIImage imageNamed:@"foursquareGray.png"] forState:UIControlStateNormal];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]) {
        [self.instagramButton setImage:[UIImage imageNamed:@"instagram.png"] forState:UIControlStateNormal];
    } else {
        [self.instagramButton setImage:[UIImage imageNamed:@"instagramGray.png"] forState:UIControlStateNormal];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFacebookActive]) {
        [self.facebookButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OpenGraph"];
    } else {
        [self.facebookButton setImage:[UIImage imageNamed:@"facebookGray.png"] forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenGraph"];
    }
}

- (IBAction)submitPost:(id)sender {
    if ([self.captionTextView.text isEqualToString:kPlaceholderAddPostCommentPrompt]) {
        [[FDPost userPost] setCaption:@""];
    } else {
        [[FDPost userPost] setCaption:self.captionTextView.text];
    }
    self.postButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    if ([self.postButtonItem.title isEqualToString:@"POST"]){
        
        //adjust for non-fb users
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken] && [[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenGraph"];
        }
        
        [[FDAPIClient sharedClient] submitPost:FDPost.userPost success:^(id result) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kJustPosted];

            //if posting to Facebook from an email sign-in account
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFacebookActive] && ![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
                NSDictionary *userInfo = @{@"identifier":[[result objectForKey:@"post"] objectForKey:@"id"]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToFacebook" object:nil userInfo:userInfo];
            }
            
            //if posting to Foursquare
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]) {
                [[FDFoursquareAPIClient sharedClient] checkInVenue:FDPost.userPost.FDVenueId postCaption:FDPost.userPost.caption withPostId:[[result objectForKey:@"post"] objectForKey:@"id"]];
            }
            //if posting to Instagram
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive] && ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToInstagram" object:nil];
            } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]){
                NSDictionary *userInfo = @{@"identifier":[[result objectForKey:@"post"] objectForKey:@"id"]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToTwitter" object:nil userInfo:userInfo];
            } else {
                [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            }
            
            //success posting image. now remove loading and notify the feed view to refresh.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshFeed" object:nil];
            
        } failure:^(NSError *error) {
             self.postButtonItem.enabled = YES;
             self.navigationItem.leftBarButtonItem.enabled = YES;
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"We couldn't send your post just yet, but we'll try again real soon!" delegate:self cancelButtonTitle:@"Okey Dokey" otherButtonTitles:nil] show];
            NSLog(@"post submission failed! %@", error.description);
        }];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
    } else {
        [[FDAPIClient sharedClient] editPost:FDPost.userPost success:^(id result) {
            //success editing post. now go back to the original feedview instead
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kJustPosted];
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshFeed" object:nil];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError *error) {
            NSLog(@"error editing post: %@",error.description);
        }];
    }
}

- (IBAction)back:(id)sender {
    [self resignFirstResponder];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [UIView animateWithDuration:.15 animations:^{
        self.filterScrollView.transform = CGAffineTransformMakeTranslation(0, 600);
        self.filteredImageView.transform = CGAffineTransformMakeTranslation(0, 600);
    } completion:^(BOOL finished) {
        [self.filterScrollView removeFromSuperview];
        self.filterScrollView = nil;
        [self.filteredImageView removeFromSuperview];
    }];
    self.filteredImageView = nil;
    UIImage *image = [[UIImage alloc] init];
    if (self.selectedFilter != nil) {
        image = [self.selectedFilter imageByFilteringImage:[info objectForKey:UIImagePickerControllerEditedImage]];
    } else {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    FDPost.userPost.photoImage = image;
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *albumName = @"FOODIA";
    [self.library addAssetsGroupAlbumWithName:albumName
                                  resultBlock:^(ALAssetsGroup *group) {
                                      
                                  }
                                 failureBlock:^(NSError *error) {
                                     NSLog(@"error adding album");
                                 }];
    
    __block ALAssetsGroup* groupToAddTo;
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        
                                        groupToAddTo = group;
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
    
    //ensure images are properly rotated
    CGImageRef imageToSave = image.CGImage;
    NSMutableDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    [metadata setObject:@"1" forKey:@"Orientation"];
    [self.library writeImageToSavedPhotosAlbum:imageToSave
                                      metadata:metadata
                               completionBlock:^(NSURL* assetURL, NSError* error) {
                                   if (error.code == 0) {
                                       // try to get the asset
                                       [self.library assetForURL:assetURL
                                                     resultBlock:^(ALAsset *asset) {
                                                         // assign the photo to the album
                                                         [groupToAddTo addAsset:asset];
                                                         }
                                                    failureBlock:^(NSError* error) {
                                                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                    }];
                                   }
                                   else {
                                       NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
                                   }
                               }];
    [self showPostInfo];
}

- (IBAction)editCategory:(id)sender {
    if (self.isEditing == YES) {
        [self performSegueWithIdentifier:@"editCategory" sender:self];
    } else [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    self.library = nil;
    [super viewDidUnload];
}
                       
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [[FDAPIClient sharedClient]deletePost:self.post success:^(id result){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshFeed" object:nil];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }failure:^(NSError *error) {
            NSLog(@"error");
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We weren't able to delete your post right now. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"You're welcome"]) {
        NSLog(@"clicked you're welcome");
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Okey Dokey"]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else self.navigationItem.rightBarButtonItem.enabled = YES;
}

-(void)profileTappedFromNewPost:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromNewPost" sender:sender];
}


#pragma mark - View lifecycle

- (void)foursquareWebview
{
    [Flurry logEvent:@"Authenticating Foursquare" timed:YES];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    NSString *authenticateURLString = [NSString stringWithFormat:@"https://foursquare.com/oauth2/authenticate?client_id=%@&response_type=token&redirect_uri=%@", @"X5ARXOQ3UMJYP12LTK5QW3SDPLZKW0L35MJNKWCPUIC4HAFR", @"http://foodia.com/images/FOODIA_red_512x512_bg.png"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:authenticateURLString]];
    [self.webView loadRequest:request];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"foursquare_access_token"] == nil) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem setHidesBackButton:YES animated:YES];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelWebview:)];
        [self.navigationItem setLeftBarButtonItem:cancel animated:YES];
        [self.navigationItem.leftBarButtonItem setTitle:@"CANCEL"];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
            [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:kFuturaMedium size:16], UITextAttributeTextColor:[UIColor blackColor]} forState:UIControlStateNormal];
        }
        [self.view addSubview:self.webView];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    }
}

#pragma mark - Web view delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.scheme isEqualToString:@"itms-apps"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)cancelWebview:(id)sender {
    [self.webView removeFromSuperview];
    self.navigationItem.leftBarButtonItem = nil;
    [self.navigationItem setHidesBackButton:NO animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *URLString = [[self.webView.request URL] absoluteString];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    if ([URLString rangeOfString:@"access_token="].location != NSNotFound) {
        NSString *accessToken = [[URLString componentsSeparatedByString:@"="] lastObject];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:accessToken forKey:@"foursquare_access_token"];
        [defaults synchronize];
        //[self dismissModalViewControllerAnimated:YES];
        [self.webView removeFromSuperview];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        self.navigationItem.leftBarButtonItem = nil;
        [self.navigationItem setHidesBackButton:NO animated:YES];
    }
}

- (IBAction)deletePost {
    [[[UIAlertView alloc]initWithTitle:@"Whoa there!" message:@"Are you sure you want to delete this post? Once deleted, you won't be able to get it back." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil] show];
}

@end
