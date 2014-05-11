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
#import "FDFoodiaTag.h"
#import "FDPostViewController.h"

NSString *const kPlaceholderAddPostCommentPrompt = @"I'm thinking...";

@interface FDNewPostViewController () <UITextViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL iPhone5;
    int previousTagOriginX;
    int previousTagButtonSize;
    int tagScrollViewContentSize;
}
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *friendsButton;
@property (weak, nonatomic) IBOutlet UIButton *tagButton;
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
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIButton *cameraButton;
@property (strong, nonatomic) NSMutableArray *tagArray;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTableView;
@property (strong, nonatomic) UIBarButtonItem *rightBarButton;
@property (weak, nonatomic) IBOutlet UILabel *tagTitleLabel;

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
@synthesize isEditingPost = _isEditingPost;

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
    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1.0]];
    self.rightBarButton = self.navigationItem.rightBarButtonItem;
    
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
    
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:kSave]) _isEditingPost = YES;
    else _isEditingPost = NO;
    
    self.library = [[ALAssetsLibrary alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPostInfo) name:@"UpdateNewPostVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
    
    if ([UIScreen mainScreen].bounds.size.height == 568){
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:kSave] || _isEditingPost){
        [self.deleteButton setHidden:NO];
        if (FDPost.userPost.isPrivate || self.post.isPrivate){
            [self.lockButton setImage:[UIImage imageNamed:@"locked"] forState:UIControlStateNormal];
        } else {
            [self.lockButton setImage:[UIImage imageNamed:@"unlocked"] forState:UIControlStateNormal];
        }
    } else {
        _isEditingPost = NO;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kDone style:UIBarButtonItemStyleBordered target:nil action:nil];
    }
    
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
        self.twitterButton.transform = CGAffineTransformMakeTranslation(-48, 0);
        self.instagramButton.transform = CGAffineTransformMakeTranslation(-48, 0);
        self.foursquareButton.transform = CGAffineTransformMakeTranslation(-48, 0);
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self showPostInfo];
}

- (void)loadTagArray{
    if (FDPost.userPost.tagArray.count){
        self.tagArray = FDPost.userPost.tagArray;
        previousTagOriginX = 3;
        previousTagButtonSize = 0;
        tagScrollViewContentSize = 0;
        [self.tagScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (FDFoodiaTag *tag in self.tagArray){
            UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [tagButton addTarget:self action:@selector(tagSegue) forControlEvents:UIControlEventTouchUpInside];
            [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
            [tagButton setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
            tagButton.layer.shadowColor = [UIColor lightGrayColor].CGColor;
            tagButton.layer.shadowRadius = 3.f;
            tagButton.layer.shadowOffset = CGSizeMake(0,0);
            tagButton.layer.shadowOpacity = .2f;
            tagButton.layer.borderColor = [UIColor colorWithWhite:.90 alpha:1].CGColor;
            tagButton.layer.borderWidth = 1.0f;
            tagButton.layer.cornerRadius = 17.0f;
            [tagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            CGSize stringSize = [tagButton.titleLabel.text sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
            [tagButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
            [tagButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [tagButton setFrame:CGRectMake(previousTagOriginX+previousTagButtonSize,4,stringSize.width+20,34)];
            previousTagButtonSize = tagButton.frame.size.width + 5;
            tagScrollViewContentSize += previousTagButtonSize;
            previousTagOriginX = tagButton.frame.origin.x;
            [self.tagScrollView addSubview:tagButton];
        }
        [self.tagScrollView setContentSize:CGSizeMake(tagScrollViewContentSize,42)];
        [self rearrangeButton:self.tagButton andView:self.tagScrollView];
    } else {
        [self disArrangeButton:self.tagButton andView:self.tagScrollView];
    }
}

- (void)tagSegue {
    [self performSegueWithIdentifier:@"ShowTagPicker" sender:self];
}

- (void)venueChosen {
    self.locationLabel.text = FDPost.userPost.locationName;
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
        [vc setIsEditingPost:YES];
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
    self.captionTextView.layer.borderWidth = 1.0f;
    self.captionTextView.layer.cornerRadius = 5.0f;
    self.captionTextView.layer.borderColor = [UIColor colorWithWhite:.4 alpha:.5].CGColor;
    self.captionTextView.contentInset = UIEdgeInsetsMake(-2,-3,0,0);
    self.captionTextView.textAlignment = NSTextAlignmentLeft;
    if (FDPost.userPost.photoImage){
        [self.photoButton setImage:FDPost.userPost.photoImage forState:UIControlStateNormal];
        [self.photoBackgroundView setAlpha:1.0];
    } else {
        [self.photoButton setImageWithURL:self.post.detailImageURL forState:UIControlStateNormal];
        [self.addPhotoLabel setHidden:YES];
        [self.cameraButton setHidden:YES];
        self.post.photoImage = self.photoButton.imageView.image;
    }
    if (self.photoButton.imageView.image) [self.photoBackgroundView setAlpha:1.0];
    
    if (self.post.category){
        [self.foodiaObjectButton setTitle:[NSString stringWithFormat:@"I'm %@", self.post.category.lowercaseString] forState:UIControlStateNormal];
    } else {
        [self.foodiaObjectButton setTitle:@"I'm..." forState:UIControlStateNormal];
    }
    
    //location section
    if (FDPost.userPost.locationName.length > 0){
        [self rearrangeButton:self.locationButton andView:self.locationLabel];
    } else {
        [self disArrangeButton:self.locationButton andView:self.locationLabel];
    }
    
    //food object section
    if (self.post.foodiaObject.length > 0){
        self.foodiaObjectLabel.text = self.post.foodiaObject;
        [self rearrangeButton:self.foodiaObjectButton andView:self.foodiaObjectLabel];
    } else {
        self.foodiaObjectLabel.text = FDPost.userPost.foodiaObject;
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
                //friendButton.titleLabel.text = @"0";
                [self animateOn:friendButton];
            } else if (friend.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [friendButton setImageWithURL:[Utilities profileImageURLForFacebookID:friend.facebookId] forState:UIControlStateNormal];
                friendButton.titleLabel.text = friend.userId;
                [self animateOn:friendButton];
            } else {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",friend.userId]];
                [friendButton setImageWithURL:url forState:UIControlStateNormal];
                friendButton.titleLabel.text = friend.userId;
                [self animateOn:friendButton];
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
    } else {
        [self.friendsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self disArrangeButton:self.friendsButton andView:self.friendsScrollView];
    }
    
    //load the tag array
    [self loadTagArray];
    
        /*//recommend section
        int index2 = 0;
        
        if (self.post.recommendedTo.count > 0){
            [self rearrangeButton:self.tagButton andView:self.recScrollView];
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
                    //recommendeeButton.titleLabel.text = recipient.fbid;
                } else if (recipient.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
                    [recommendeeButton setImageWithURL:[Utilities profileImageURLForFacebookID:recipient.facebookId] forState:UIControlStateNormal];
                    [self animateOn:recommendeeButton];
                    recommendeeButton.titleLabel.text = recipient.userId;
                } else {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",recipient.userId]];
                    [recommendeeButton setImageWithURL:url forState:UIControlStateNormal];
                    [self animateOn:recommendeeButton];
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
        } else {
            [self disArrangeButton:self.tagButton andView:self.recScrollView];
            [self.recScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }*/
}

-(void)animateOn:(UIButton*)button{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [button setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)rearrangeButton:(UIButton*)button andView:(UIView*)view  {
    
    [UIView animateWithDuration:.3 delay:.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        button.transform = CGAffineTransformMakeTranslation(-100, 0);
        [view setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)disArrangeButton:(UIButton*)button andView:(UIView*)view  {
    [UIView animateWithDuration:.3 delay:.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        button.transform = CGAffineTransformIdentity;
        [view setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TagCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    UIView *cellbg = [[UIView alloc] init];
    [cellbg setBackgroundColor:kColorLightBlack];
    cell.selectedBackgroundView = cellbg;
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
    [cell.textLabel setText:[self.searchResults objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - UITextFieldDelegate Methods

- (void)willShowKeyboard:(NSNotification *)notification {
    self.searchResultsTableView.scrollEnabled = YES;
    [self.facebookButton setHidden:YES];
    [self.instagramButton setHidden:YES];
    [self.twitterButton setHidden:YES];
    [self.foursquareButton setHidden:YES];
    [self.lockButton setHidden:YES];
    [self.tagTitleLabel setHidden:NO];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:kCancel style:UIBarButtonItemStyleBordered target:self action:@selector(doneEditing)];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    
   /* if (FDPost.userPost.foodiaObject.length) {
        [self.tagTitleLabel setText:[NSString stringWithFormat:@"Select a tag for %@",FDPost.userPost.foodiaObject]];
    }
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    if (iPhone5){
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+140.0, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+205.0, 0.0);
    }
    self.searchResultsTableView.contentInset = contentInsets;
    //self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
     aRect.size.height -= kbSize.height;
     if (!CGRectContainsPoint(aRect, self.tagButton.frame.origin) ) {
     CGPoint scrollPoint = CGPointMake(0.0, 140.0);
     [self.searchResultsTableView setContentOffset:scrollPoint animated:YES];
     }*/
}

- (void)willHideKeyboard {
    [self.searchResultsTableView setContentOffset:CGPointZero animated:YES];
    [self.searchResultsTableView setScrollEnabled:NO];
    [self.facebookButton setHidden:NO];
    [self.instagramButton setHidden:NO];
    [self.twitterButton setHidden:NO];
    [self.foursquareButton setHidden:NO];
    [self.lockButton setHidden:NO];
    [self.tagTitleLabel setHidden:YES];
    [self.searchResults removeAllObjects];
    if (_isEditingPost) {
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:kSave style:UIBarButtonItemStyleBordered target:self action:@selector(submitPost:)];
        [[self navigationItem] setRightBarButtonItem:saveButton];
    } else {
        UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:kPost style:UIBarButtonItemStyleBordered target:self action:@selector(submitPost:)];
        [[self navigationItem] setRightBarButtonItem:postButton];
    }
}

-(void)doneEditing {
    [[self view] endEditing:YES];
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
        textView.font = [UIFont fontWithName:kHelveticaNeueThin size:16];
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
    NSLog(@"photo image? %@",FDPost.userPost.photoImage);
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:[FDPost.userPost photoImage] ? @"Remove Photo" : nil
                                         otherButtonTitles:@"Take Photo", nil];
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
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        [self takePhoto];
    } else [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
    /*switch (buttonIndex) {
        case 0: //remove photo
            if ([FDPost.userPost photoImage])
                [self removePhoto];
            else {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self takePhoto];
            }
            break;*/
        /*case 1: // new photo
            if ([FDPost.userPost photoImage]) {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                    [self choosePhoto];
            } else {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                    [self takePhoto];
            }
            break;*/
       /* case 1:
            [actionSheet dismissWithClickedButtonIndex:1 animated:YES];
        default:
            break;
    }*/
}

- (void)choosePhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setDelegate:self];
    [picker setAllowsEditing:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)takePhoto {
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:kSave]){
        FDCameraViewController *vc;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
            vc = [storyboard5 instantiateViewControllerWithIdentifier:@"Camera"];
        } else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            vc = [storyboard instantiateViewControllerWithIdentifier:@"Camera"];
        }
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [vc setShouldBeEditing:YES];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [super dismissViewControllerAnimated:YES completion:nil];
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

- (IBAction)togglePrivate {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPrivatePost]
                                            forKey:kDefaultsPrivatePost];
    [self updateCrossPostButtons];
}

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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPrivatePost]) {
        [self.lockButton setImage:[UIImage imageNamed:@"locked"] forState:UIControlStateNormal];
        [self.facebookButton setEnabled:NO];
        [self.twitterButton setEnabled:NO];
        [self.instagramButton setEnabled:NO];
        [self.foursquareButton setEnabled:NO];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultsFacebookActive];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultsFoursquareActive];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultsInstagramActive];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultsTwitterActive];
    } else {
        [self.lockButton setImage:[UIImage imageNamed:@"unlocked"] forState:UIControlStateNormal];
        [self.facebookButton setEnabled:YES];
        [self.twitterButton setEnabled:YES];
        [self.instagramButton setEnabled:YES];
        [self.foursquareButton setEnabled:YES];
    }
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
    
    //adjust for non-fb users
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken] && [[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenGraph"];
    }
    
    if ([self.postButtonItem.title isEqualToString:kPost]){
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
        //[self.postButtonItem setEnabled:NO];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        
        if ([self.captionTextView.text isEqualToString:kPlaceholderAddPostCommentPrompt]) {
            [[FDPost userPost] setCaption:@""];
        } else {
            [[FDPost userPost] setCaption:self.captionTextView.text];
        }
        
        //adjust for private posts
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPrivatePost]) {
            FDPost.userPost.isPrivate = YES;
        } else {
            FDPost.userPost.isPrivate = NO;
        }
            
            [[FDAPIClient sharedClient] submitPost:FDPost.userPost success:^(id result) {
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
                }
                
            } failure:^(NSError *error) {
                //[((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
                
            }];
        }];
    } else {
        [((FDAppDelegate *)[UIApplication sharedApplication].delegate) showLoadingOverlay];
        [[FDAPIClient sharedClient] editPost:FDPost.userPost success:^(id result) {
            [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
            FDPostViewController *destinationVC = (FDPostViewController*)[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
            [destinationVC setShouldReframe:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshPostView" object:nil];
            [self.navigationController popViewControllerAnimated:YES];
            
            //gratuitious sharing section
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFacebookActive] && ![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
                NSDictionary *userInfo = @{@"identifier":[[result objectForKey:@"post"] objectForKey:@"id"]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToFacebook" object:nil userInfo:userInfo];
            }
            
            //if posting to Foursquare
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsFoursquareActive]) {
                [[FDFoursquareAPIClient sharedClient] checkInVenue:FDPost.userPost.foursquareid postCaption:FDPost.userPost.caption withPostId:[[result objectForKey:@"post"] objectForKey:@"id"]];
            }
            //if posting to Instagram
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive] && ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToInstagram" object:nil];
            } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTwitterActive]){
                NSDictionary *userInfo = @{@"identifier":[[result objectForKey:@"post"] objectForKey:@"id"]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PostToTwitter" object:nil userInfo:userInfo];
            }

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
    [self performSegueWithIdentifier:@"editCategory" sender:self];
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
            NSLog(@"Error deleting this post: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We weren't able to delete your post right now. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"You're welcome"]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
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
        [self.navigationItem.leftBarButtonItem setTitle:kCancel];
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
    NSLog(@"cancel webview");
    [self.webView removeFromSuperview];
    self.navigationItem.leftBarButtonItem = nil;
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultsFoursquareActive];
    [self updateCrossPostButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *URLString = [[self.webView.request URL] absoluteString];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    if ([URLString rangeOfString:@"access_token="].location != NSNotFound) {
        NSString *accessToken = [[URLString componentsSeparatedByString:@"="] lastObject];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:accessToken forKey:@"foursquare_access_token"];
        [defaults synchronize];
        [self.webView removeFromSuperview];
        self.navigationItem.leftBarButtonItem = nil;
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
}

- (IBAction)deletePost {
    [[[UIAlertView alloc]initWithTitle:@"Whoa there!" message:@"Are you sure you want to delete this post? Once deleted, you won't be able to get it back." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil] show];
}

@end
