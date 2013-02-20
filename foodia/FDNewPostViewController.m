//
//  FDNewPostViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 11/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDNewPostViewController.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDAPIClient.h"
#import <CoreLocation/CoreLocation.h>
#import "Utilities.h"
#import "FDVenue.h"
#import "FDFoursquareAPIClient.h"
#import "FDTagFriendsViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "Constants.h"
#import "FDProfileViewController.h"

#define BLUE_TEXT_COLOR [UIColor colorWithRed:102.0/255.0 green:153.0/255.0 blue:204.0/255.0 alpha:1.0]
NSString *const kPlaceholderAddPostCommentPrompt = @"I'M THINKING...";

@interface FDNewPostViewController () <UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UIButton *posterButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoBoxView;
@property (weak, nonatomic) IBOutlet UIButton *friendsButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UIButton *foodiaObjectButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *noLocationActivityIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *locationContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *confirmLocationImageView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *foodiaObjectLabel;
@property (weak, nonatomic) IBOutlet UIImageView *categoryImageView;
@property (weak, nonatomic) IBOutlet UIView *foodiaObjectContainer;
@property (weak, nonatomic) IBOutlet UIView *friendsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak,nonatomic) NSString *postReturnURL;
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;
@property (nonatomic, readwrite, retain) UIWebView *webView;
@property (strong, atomic) ALAssetsLibrary *library;
@property UIImageOrientation *imageOrientationWhenAddedToScreen;
- (IBAction)editPhoto:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)submitPost:(id)sender;
- (IBAction)editCategory:(id)sender;

@end

@implementation FDNewPostViewController
@synthesize confirmLocationImageView = _confirmLocationImageView;
@synthesize locationLabel = _locationLabel;
@synthesize mapView = _mapView;
@synthesize categoryLabel = _categoryLabel;
@synthesize foodiaObjectLabel = _foodiaObjectLabel;
@synthesize categoryImageView = _categoryImageView;
@synthesize foodiaObjectContainer = _foodiaObjectContainer;
@synthesize foursquareButton, instagramButton, twitterButton;
@synthesize postReturnURL;
@synthesize webView = _webView;
@synthesize library;
@synthesize imageOrientationWhenAddedToScreen;

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
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"SAVE"]){
        NSLog(@"edit post status... showing delete button");
        self.deleteButton.layer.cornerRadius = 17.0;
        self.deleteButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.deleteButton.layer.borderWidth = 0.5;
        [self.deleteButton setHidden:NO];
        [self.facebookButton setHidden:YES];
        [self.foursquareButton setHidden:YES];
        [self.twitterButton setHidden:YES];
        [self.instagramButton setHidden:YES];
    } else {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"POST" style:UIBarButtonItemStyleBordered target:nil action:nil];

    }
    self.photoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoButton.imageView.clipsToBounds = YES;
    [self updateCrossPostButtons];
    self.posterImageView.layer.cornerRadius = 5.0f;
    self.posterImageView.clipsToBounds = YES;
    self.posterImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.posterImageView.layer.borderWidth = .5f;
    [self.posterImageView setImageWithURL:[Utilities profileImageURLForCurrentUser]];
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.delegate = self;
    
    self.friendsButton.layer.cornerRadius = 17.0;
    self.friendsButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.friendsButton.layer.borderWidth = 0.5;
    self.locationButton.layer.cornerRadius = 17.0;
    self.locationButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.locationButton.layer.borderWidth = 0.5;
    self.foodiaObjectButton.layer.cornerRadius = 17.0;
    self.foodiaObjectButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.foodiaObjectButton.layer.borderWidth = 0.5;
    self.recButton.layer.cornerRadius = 17.0;
    self.recButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.recButton.layer.borderWidth = 0.5;
    //always toggle foursquare sharing off to start
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:kDefaultsFoursquareActive];
    [self updateCrossPostButtons];
    self.library = [[ALAssetsLibrary alloc]init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (FDPost.userPost.locationName) {
        [self venueChosen];
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView addAnnotation:FDPost.userPost];
        [self.mapView setRegion:MKCoordinateRegionMake(FDPost.userPost.coordinate, MKCoordinateSpanMake(0.002, 0.002))];
    } else if (FDPost.userPost.location == nil) {
        [self.locationManager startUpdatingLocation];
        [self findingLocation];
    } else {
        [self locationFound];
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self showPostInfo];
}

- (void)findingLocation {
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

- (void)venueChosen {
    self.locationContainerView.hidden = NO;
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
    } 
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self locationFailed];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
        [self locationFound];
        FDPost.userPost.location = location;
        [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:NULL failure:NULL];
        [manager stopUpdatingLocation];

}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        [self locationFound];
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
        self.photoButton.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.photoButton.imageView.layer.borderWidth = .5f;
    } else {
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setImageWithURL:self.post.detailImageURL];
        [self.photoButton setImage:imageView.image forState:UIControlStateNormal];
        self.post.photoImage = imageView.image;
    }
    self.photoButton.hidden = !self.post.photoImage;
    [self.foodiaObjectButton setTitle:[NSString stringWithFormat:@"I'M %@", self.post.category.uppercaseString] forState:UIControlStateNormal];
    self.categoryImageView.image = [FDNewPostViewController imageForCategory:self.post.category];
    
    //food object section
    self.foodiaObjectLabel.text = self.post.foodiaObject.uppercaseString;
    
    //social tagging section
    [self.friendsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.friendsScrollView.showsHorizontalScrollIndicator=NO;
    
    float imageSize = 34.0;
    float space = 10.0;
    int index = 0;
    for (FDUser *friend in [FDPost.userPost.withFriends allObjects]) {
        UIImageView *friendView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.friendsScrollView.frame.origin.x)+((space+imageSize)*index)),(self.friendsScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *friendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        friendButton.titleLabel.text = friend.facebookId;
        //friendButton.titleLabel.text = [friend objectForKey:@"facebookId"];
        friendButton.titleLabel.hidden = YES;
        [friendButton addTarget:self action:@selector(profileTappedFromNewPost:) forControlEvents:UIControlEventTouchUpInside];
        //[friendView setImageWithURL:[Utilities profileImageURLForFacebookID:[friend objectForKey:@"facebookId"]]];
        [friendView setImageWithURL:[Utilities profileImageURLForFacebookID:friend.facebookId]];
        friendView.userInteractionEnabled = YES;
        friendView.clipsToBounds = YES;
        friendView.layer.cornerRadius = 5.0;
        friendView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
        
        [friendButton setFrame:friendView.frame];
        [self.friendsScrollView addSubview:friendView];
        [self.friendsScrollView addSubview:friendButton];
        index++;
    }
    [self.friendsScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),34)];

    
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"POST"]) {
    //recommend section
    int index2 = 0;
    
    [self.recScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.recScrollView.showsHorizontalScrollIndicator=NO;
    
    for (FDUser *recipient in [FDPost.userPost.recommendedTo allObjects]) {
        UIImageView *recommendee = [[UIImageView alloc] initWithFrame:CGRectMake(((self.recScrollView.frame.origin.x)+((space+imageSize)*index2)),(self.recScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *recommendeeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        recommendeeButton.titleLabel.hidden = YES;
        [recommendeeButton addTarget:self action:@selector(profileTappedFromNewPost:) forControlEvents:UIControlEventTouchUpInside];
        recommendeeButton.titleLabel.text = recipient.facebookId;
        [recommendee setImageWithURL:[Utilities profileImageURLForFacebookID:recipient.facebookId]];
        
        recommendee.userInteractionEnabled = YES;
        recommendee.clipsToBounds = YES;
        recommendee.layer.cornerRadius = 5.0;
        recommendee.frame = CGRectMake(((space+imageSize)*index2),0,imageSize, imageSize);
        
        [recommendeeButton setFrame:recommendee.frame];
        [self.recScrollView addSubview:recommendee];
        [self.recScrollView addSubview:recommendeeButton];
        index2++;
    }
    [self.recScrollView setContentSize:CGSizeMake(((space*(index2+1))+(imageSize*(index2+1))),34)];
    } else [self.recButton setHidden:YES];
    //social tagging section
    /*[self.friendsContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray *friends = [[self.post.withFriends allObjects] subarrayWithRange:NSMakeRange(0, MIN(self.post.withFriends.count, 12))];
    if (friends.count > 0){
        CGFloat friendImageSize = 30.f;
        CGFloat spacer = (self.friendsContainerView.frame.size.width - 4 * friendImageSize)/12.0;
        [friends enumerateObjectsUsingBlock:^(FDUser *friend, NSUInteger idx, BOOL *stop) {
            int column = idx % 12;
            int row = 1;
            CGRect frame = CGRectMake(spacer + column * (spacer + friendImageSize),
                                  17 + spacer + row * (spacer + friendImageSize),
                                  friendImageSize,
                                  friendImageSize);
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.backgroundColor = [UIColor clearColor];
            imageView.layer.cornerRadius = 5.0f;
            imageView.clipsToBounds=YES;
            NSLog(@"friend.facebookId: %@",friend.facebookId);
            [imageView setImageWithURL:[Utilities profileImageURLForFacebookID:friend.facebookId]];
            [self.friendsContainerView addSubview:imageView];
            self.friendsLabel.text = @"I'M WITH";
        }];
    }
    //reccomend section
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"POST"]){
        [self.recommendationsContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        NSArray *recommendees = [[self.post.recommendedTo allObjects] subarrayWithRange:NSMakeRange(0, MIN(self.post.recommendedTo.count, 8))];
        if (recommendees.count > 0){
            CGFloat friendImageSize = 30.f;
            CGFloat spacer = (self.recommendationsContainerView.frame.size.width - 4 * friendImageSize)/5.0;
            [recommendees enumerateObjectsUsingBlock:^(FDUser *friend, NSUInteger idx, BOOL *stop) {
                int column = idx % 4;
                int row = (idx <= 3) ? 0 : 1;
                CGRect frame = CGRectMake(spacer + column * (spacer + friendImageSize),
                                          17 + spacer + row * (spacer + friendImageSize),
                                          friendImageSize,
                                          friendImageSize);
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
                imageView.backgroundColor = [UIColor clearColor];
                imageView.layer.cornerRadius = 5.0f;
                imageView.clipsToBounds=YES;
                [imageView setImageWithURL:[Utilities profileImageURLForFacebookID:friend.facebookId]];
                [self.recommendationsContainerView addSubview:imageView];
            }];
        }
    } else self.post.recommendedTo = nil;
    self.noFriendsContainerView.hidden = (self.post.withFriends.count > 0);
    self.friendsContainerView.hidden = (self.post.withFriends.count == 0);
    
    self.recommendationsContainerView.hidden = (self.post.recommendedTo.count == 0);
    self.noRecommendationsContainerView.hidden = (self.post.recommendedTo.count > 0);*/
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
        textView.textColor = [UIColor darkGrayColor];
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
        textView.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16];
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

/*- (void)loadTumblrApi {
    oauthTumblrAppViewController *vc = [[oauthTumblrAppViewController alloc] init];
    [self presentModalViewController:vc animated:YES];
}*/
-(void)removePhoto {
    FDPost.userPost.photoImage = nil;
    [UIView animateWithDuration:0.25 animations:^{
        CGAffineTransform shrinkTransform = CGAffineTransformMakeScale(0.001, 0.001);
        self.photoBoxView.transform = shrinkTransform;
        self.photoButton.transform = shrinkTransform;
        self.photoBoxView.alpha = 0.0;
        self.photoButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self showPostInfo];
        self.photoButton.transform = CGAffineTransformIdentity;
        self.photoBoxView.transform = CGAffineTransformIdentity;
        self.photoBoxView.alpha = 1.0;
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
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]
                                            forKey:@"OpenGraph"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]) [(FDAppDelegate *)[UIApplication sharedApplication].delegate getPublishPermissions];
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]) {
        [self.facebookButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    } else {
        [self.facebookButton setImage:[UIImage imageNamed:@"facebookGray.png"] forState:UIControlStateNormal];
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
        [[FDAPIClient sharedClient] submitPost:FDPost.userPost success:^(id result) {
            //if posting to Twitter
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]) [self postToTwitter:[[result objectForKey:@"post"] objectForKey:@"id"]];
            //if posting to Foursquare
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]) {
                [[FDFoursquareAPIClient sharedClient] checkInVenue:FDPost.userPost.FDVenueId postCaption:FDPost.userPost.caption withPostId:[[result objectForKey:@"post"] objectForKey:@"id"]];
            }
            
            //if posting to Instagram
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]) {
                UIImage *instaImage = FDPost.userPost.photoImage;
                NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
                if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
                    //now create a file path with an .igo file extension
                    NSString *instaPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/instaImage.igo"];
                    [UIImageJPEGRepresentation(instaImage,1.0)writeToFile:instaPath atomically:YES];
                    
                    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:instaPath]];
                    
                    self.documentInteractionController.UTI = @"com.instagram.exclusivegram";
                    self.documentInteractionController.annotation = [NSDictionary dictionaryWithObject:@"#FOODIA" forKey:@"InstagramCaption"];
                    
                    [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];

                    [((FDSlidingViewController *)self.navigationController.presentingViewController) showInstagram:self.documentInteractionController];
                    self.postButtonItem.enabled = YES;
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
                    UIAlertView *errorToShare = [[UIAlertView alloc] initWithTitle:@"Instagram unavailable " message:@"We were unable to connect to Instagram on this device" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                    [errorToShare show];
                }
            }
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSError *error) {
             self.postButtonItem.enabled = YES;
             self.navigationItem.leftBarButtonItem.enabled = YES;
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Something went wrong..." message:@"Sorry, but we couldn't send this post." delegate:nil cancelButtonTitle:@"Try Again" otherButtonTitles:nil] show];
            NSLog(@"post submission failed! %@", error.description);
        }];
    } else {
        [[FDAPIClient sharedClient] editPost:FDPost.userPost success:^(id result) {
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
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
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    FDPost.userPost.photoImage = image;

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
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editCategory:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    self.library = nil;
    [super viewDidUnload];
}

- (void)postToTwitter:(id)postId {
    // Create an account store object.
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    // Create an account type that ensures Twitter accounts are retrieved.
    ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    //[self canTweetStatus];
    
    // Request access from the user to use their Twitter accounts.
    [accountStore requestAccessToAccountsWithType:twitterAccountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
                             // Grab the available accounts
                             NSArray *twitterAccounts = [accountStore accountsWithAccountType:twitterAccountType];
                             
                             if ([twitterAccounts count] > 0) {
                                 NSLog(@"twitter account exists");
                                 // Use the first account for simplicity
                                 ACAccount *account = [twitterAccounts objectAtIndex:0];
                                 
                                 // Now make an authenticated request to our endpoint
                                 
                                 //  The endpoint that we wish to call
                                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
                                 
                                 //  Build the request with our parameter
                                 TWRequest *request =
                                 [[TWRequest alloc] initWithURL:url
                                                     parameters:nil
                                                  requestMethod:TWRequestMethodPOST];
                                 
                                 NSData *myData = [[@"Posting with #FOODIA! http://posts.foodia.com/p/" stringByAppendingString:[postId stringValue]] dataUsingEncoding:NSUTF8StringEncoding];
                                 [request addMultiPartData:myData withName:@"status" type:@"text/plain"];
                                 // Attach the account object to this request
                                 [request setAccount:account];
                                 
                                 [request performRequestWithHandler:
                                  ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                      if (!responseData) {
                                          // inspect the contents of error
                                          NSLog(@"%@", error);
                                          
                                      } else {

                                      }
                                      [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationNewsFeedShouldRefresh" object:nil];
                                      
                                      //[self finished];
                                      
                                  }];
                                 
                             } // if ([twitterAccounts count] > 0)
        } else {
            // The user rejected your request
            UIAlertView *errorSharingTwitter = [[UIAlertView alloc] initWithTitle:@"Twitter unavailable " message:@"We were unable to connect to your Twitter account on this device" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorSharingTwitter show];
        }// if (granted)
    }];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [[FDAPIClient sharedClient]deletePost:self.post success:^(id result){
            [self.navigationController popToRootViewControllerAnimated:YES];
        }failure:^(NSError *error) {
            NSLog(@"error");
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We weren't able to delete your post right now. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }];
    } else self.navigationItem.rightBarButtonItem.enabled = YES;
}

/*- (NSString *)twitterStatusString {
    NSLog(@"generating twitter status:");
    //if ([[FDPost userPost].caption length]) {
 
        NSString *urlString         = ([FDPost userPost].detailImageURL);
        NSMutableString *message    = [[[FDPost userPost] caption] mutableCopy];
        
        //if (message.length + urlString.length > 140) {
        //    while (message.length > 139) message = [[message substringToIndex:message.length-1] mutableCopy];
        //}
        
        //return [NSString stringWithFormat:@"%@…%@", message, urlString];
        
    //} else {
        
        NSLog(@"mutable copy of twitter post: %@", [NSString stringWithFormat:@"Posting with #FOODIA! http://posts.foodia.com/p/%@", postReturnURL]);
}*/

-(void)profileTappedFromNewPost:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromNewPost" sender:sender];
}


#pragma mark - View lifecycle

- (void)foursquareWebview
{
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
        [TestFlight passCheckpoint:@"Authenticating Foursquare!"];
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
