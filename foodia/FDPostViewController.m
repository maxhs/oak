//
//  FDPostViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostViewController.h"
#import "FDPost.h"
#import "FDCache.h"
#import "FDAPIClient.h"
#import "AFNetworking.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "UIImageView+AFNetworking.h"
#import "Utilities.h"
#import "FDUser.h"
#import <QuartzCore/QuartzCore.h>
#import "FDCommentCell.h"
#import "FDProfileViewController.h"
#import "FDRecommendViewController.h"
#import "FDComment.h"
#import "Constants.h"
#import "FDPostTableViewController.h"
#import "FDSlidingViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <MessageUI/MessageUI.h>
#import "FDNewPostViewController.h"

#define COMMENT_SECTION 1
#define LIKE_SECTION 0
#define RECOMMEND_SECTION 2
NSString *const kPlaceholderAddCommentPrompt = @"Add your two cents...";
static NSDictionary *placeholderImages;

@interface FDPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak,nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *posterButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *recCountLabel;
@property (weak, nonatomic) IBOutlet UITextView *socialLabel;
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UITextView *whiteCaption;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIView *tableHeaderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak,nonatomic) IBOutlet UILabel *postTitle;
@property (weak,nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) FDPost *post;
@property (nonatomic, strong) NSArray *comments;
@property (strong, nonatomic) NSString *likerFacebookId;
@property (strong, nonatomic) NSString *commenterFacebookId;
@property CGRect captionRect;
@property CGRect socialLabelRect;
@property CGRect newTableHeaderView;
@property CGRect screenRect;
@property CGFloat screenWidth;
@property CGFloat screenHeight;
@property CGFloat photoImageViewY;
@property CGFloat photoImageViewX;
@end

@implementation FDPostViewController

@synthesize likersScrollView, addComment, likerFacebookId, commenterFacebookId, captionRect, socialLabelRect, newTableHeaderView, whiteCaption, screenRect, screenWidth, screenHeight, doubleTap, photoImageViewY, photoImageViewX;

+ (void)initialize {
    if (self == [FDPostViewController class]) {
        placeholderImages = @{
        @"Eating"   : [UIImage imageNamed:@"detailPlaceholderEating.png"],
        @"Drinking" : [UIImage imageNamed:@"detailPlaceholderDrinking.png"],
        @"Making"  : [UIImage imageNamed:@"detailPlaceholderMaking.png"],
        @"Shopping" : [UIImage imageNamed:@"detailPlaceholderShopping.png"]};
    }
}

+ (UIImage *)placeholderImageForCategory:(NSString *)category {
    return [placeholderImages objectForKey:category];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setBool:true
                                            forKey:kDefaultsEnlargePhoto];
    [[NSUserDefaults standardUserDefaults] setBool:false
                                            forKey:kDefaultsBlackView];
    self.screenRect = [[UIScreen mainScreen] bounds];
    self.screenWidth = screenRect.size.width;
    self.screenHeight = screenRect.size.height;
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomPhoto:)];
    self.doubleTap.numberOfTapsRequired = 2;
    self.photoImageViewX = 0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    BOOL existingUserPost = [[NSUserDefaults standardUserDefaults] boolForKey:@"existingUserPost"];
    if (!existingUserPost) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
        [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.70]];
        UIImageView *newUser = [[UIImageView alloc] init];
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen ].bounds.size.height == 568.0)){
            [newUser setImage:[UIImage imageNamed:@"newUserPost@2x.png"]];
        } else {
            [newUser setImage:[UIImage imageNamed:@"newUserPostShort.png"]];
        }
        [newUser setFrame:CGRectMake(0,0,320,screenHeight-20)];
        [blackView addSubview:newUser];
        [blackView setTag:334];
        UIButton *dismiss = [[UIButton alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
        [dismiss setBackgroundColor:[UIColor clearColor]];
        [dismiss addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
        [blackView addSubview:dismiss];
        [self.view addSubview:blackView];
        [self.view bringSubviewToFront:self.recButton.imageView];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"existingUserPost"];
    }
}


- (void)dismissSelf {
    UIView *blackView = [self.view viewWithTag:334];
    
    [UIView animateWithDuration:0.25f
                          delay:0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         [blackView setAlpha:0.0f];
                     }
                     completion: ^(BOOL finished){
                         [blackView removeFromSuperview];
                     }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:@"Post Detail view"];
    // look for a cached detail version of this post
    // if none exists, load from the API
    /*FDPost *cachedPost = [FDCache getCachedPostForIdentifier:self.postIdentifier];
    if (cachedPost != nil) {
        NSLog(@"using cached post");
        self.post = cachedPost;
    } else */[self refresh];
    
    self.navigationItem.rightBarButtonItem = nil;
    if (self.post != nil)[self showPostDetails];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.postIdentifier) [userInfo setObject:self.postIdentifier forKey:@"postId"];
    if (self.post.likeCount) [userInfo setObject:self.post.likeCount forKey:@"likeCount"];
    if (self.post.likers) [userInfo setObject:self.post.likers forKey:@"likers"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePostNotification" object:nil userInfo:userInfo];
    //temporary comment out
    //[FDCache cachePost:self.post];
    //[FDCache cacheDetailPost:self.post];
    [self.postRequestOperation cancel];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)recommend {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"I'm recommending something on FOODIA!" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend via Facebook",@"Send a Text", @"Send an Email", nil];
    [actionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UpdatePost"]) {
        NSLog(@"sender from prepare for segue: %@",sender);
        FDNewPostViewController *newPostVC = [segue destinationViewController];
        [newPostVC.postButtonItem setTitle:@"SAVE"];
        [FDPost setUserPost:self.post];
    } else if ([segue.identifier isEqualToString:@"Recommend"]) {
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_stream"] == NSNotFound) {
            // No permissions found in session, ask for it
            [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_stream", @"email",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                if (!error) {
                    if ([FBSession.activeSession.permissions
                         indexOfObject:@"publish_stream"] != NSNotFound) {
                        // If permissions granted, go to the rec controller
                        FDRecommendViewController *vc = [segue.destinationViewController viewControllers][0];
                        [vc setPost:self.post];
                    } else {
                        [self dismissModalViewControllerAnimated:YES];
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we'll need your permission in order to post recommendations to Facebook." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                    }
                }
            }];
        } else if ([FBSession.activeSession.permissions
                    indexOfObject:@"publish_stream"] != NSNotFound) {
            FDRecommendViewController *vc = [segue.destinationViewController viewControllers][0];
            [vc setPost:self.post];
        }
    } else if ([segue.identifier isEqualToString:@"ShowProfile"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        [profileVC initWithUserId:self.post.user.facebookId];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromLikers"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        UIButton *button = (UIButton *) sender;
        [profileVC initWithUserId:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromComment"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        UIButton *button = (UIButton *) sender;
        [profileVC initWithUserId:button.titleLabel.text];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 0) {
        [self performSegueWithIdentifier:@"Recommend" sender:self.post];
    } else if(buttonIndex == 1) {
        NSLog(@"trying to message");
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",self.post.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self presentModalViewController:viewController animated:YES];
        }
    } else if(buttonIndex == 2) {
        
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            NSLog(@"trying to mail");
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", self.post.foodiaObject, self.postIdentifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:self.post.foodiaObject];
            if (controller) [self presentModalViewController:controller animated:YES];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your recommendation. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
    } else if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your mail. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)refresh {
    self.postRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getDetailsForPostWithIdentifier:self.postIdentifier success:^(FDPost *post) {
        self.post = post;
        [self showPostDetails];
    } failure:^(NSError *error) {
        NSLog(@"ERROR LOADING POST %@", error.description);
    }];
    
    [self.postRequestOperation start];
}

- (void)showPostDetails {
    
    if ([self.post.user.facebookId isEqualToString:[[NSUserDefaults standardUserDefaults]objectForKey:@"FacebookID"]]){
        NSLog(@"the following post identifier: %@",self.post.identifier);
        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:@"EDIT" style:UIBarButtonItemStyleBordered target:self action:@selector(updatePost)];
        self.navigationItem.rightBarButtonItem = edit;
    }
    [self.posterButton setImageWithURL:[Utilities profileImageURLForFacebookID:self.post.user.facebookId] forState:UIControlStateNormal];
    self.posterButton.layer.cornerRadius = 25.0f;
    self.posterButton.clipsToBounds = YES;
    if (self.post.detailImageUrlString.length) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadWithURL:self.post.detailImageURL options:0 progress:^(NSUInteger receivedSize, long long expectedSize) {
            self.progressView.progress = (float)receivedSize/(float)expectedSize;
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (finished) {
                self.photoImageView.image = image;
                self.photoImageView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
                self.photoImageView.layer.shadowOffset = CGSizeMake(0, 1);
                self.photoImageView.layer.shadowOpacity = 1;
                self.photoImageView.layer.shadowRadius = 3.0;
                self.photoImageView.clipsToBounds = NO;
            }
        }];
    } else [self.photoImageView setImage:[FDPostViewController placeholderImageForCategory:self.post.category]];
    
    self.postTitle.text = [Utilities postedAt:self.post.postedAt];
    self.socialLabel.text   = self.post.detailString;
    self.captionTextView.text  = [NSString stringWithFormat:@"\"%@\"", self.post.caption];
    self.likeCountLabel.text = [NSString stringWithFormat:@"%@", self.post.likeCount];
    self.recCountLabel.text = [NSString stringWithFormat:@"%d", [self.post.recommendedTo count]];
    //set social label frame size
    if(CGRectIsEmpty(socialLabelRect)) {
        socialLabelRect = self.socialLabel.frame;
        socialLabelRect.size.height = self.socialLabel.contentSize.height;
        self.socialLabel.frame = socialLabelRect;
    }
    //set caption/message height
    if (CGRectIsEmpty(captionRect) && self.post.caption.length){
        captionRect = self.captionTextView.frame;
        captionRect.size.height = self.captionTextView.contentSize.height;
        captionRect.origin.y += self.socialLabel.contentSize.height;
        self.captionTextView.frame = captionRect;
    } else if (!self.post.caption.length) {
        captionRect = self.captionTextView.frame;
        captionRect.size.height = 0;
        captionRect.origin.y += self.socialLabel.contentSize.height-12;
        self.captionTextView.frame = captionRect;
    }
    
    //set the tableHeaderView frame according to social label and caption
    if (CGRectIsEmpty(newTableHeaderView)){
        newTableHeaderView = [self.tableHeaderView frame];
        [self.tableHeaderView setBounds:CGRectMake(newTableHeaderView.origin.x,
                                                   newTableHeaderView.origin.y,
                                                   newTableHeaderView.size.width,
                                                   newTableHeaderView.size.height+self.captionTextView.frame.size.height+self.socialLabel.frame.size.height+8)];
        [self.photoImageView setFrame:CGRectMake(5,5,310,310)];
        [self.posterButton setFrame:CGRectMake(267,3,50,50)];
    }
    
    //hide quotes if appropriate
    if (self.post.caption.length) self.captionTextView.hidden = NO;
    else self.captionTextView.hidden = YES;
    
    UIImage *likeButtonImage;
    if (self.post.isLikedByUser) likeButtonImage = [UIImage imageNamed:@"feedLikeButtonRed.png"];
    else likeButtonImage = [UIImage imageNamed:@"feedLikeButtonGray.png"];
    
    [self.likeButton setImage:likeButtonImage forState:UIControlStateNormal];
    
    [self.tableView setTableHeaderView:self.tableHeaderView];
    [self showLikers];
    [self showComments];
}

- (void)showComments {
    self.comments = [self.post.comments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"epochTime" ascending:NO]]];
    [self.tableView reloadData];
}

- (void)updatePost {
    NSLog(@"should be updating post");
    [self performSegueWithIdentifier:@"UpdatePost" sender:self.post];
}

- (IBAction)likeButtonTapped:(id)sender {
    if (self.post.isLikedByUser) {
        [[FDAPIClient sharedClient] unlikePost:self.post
                                       success:^(FDPost *newPost) {
                                           self.post = newPost;
                                           [self showPostDetails];
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }];
        [self refresh];
    } else {
        [[FDAPIClient sharedClient] likePost:self.post
                                     success:^(FDPost *newPost) {
                                         self.post = newPost;
                                         int t = [newPost.likeCount intValue] + 1;
                                         
                                         [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];

                                         [self showPostDetails];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }];
        [self refresh];
    }
}
-(void)makeBlackView {
    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.screenWidth,self.screenHeight)];
    self.whiteCaption.text = self.captionTextView.text;
    self.whiteCaption.textAlignment = UITextAlignmentCenter;
    self.whiteCaption.textColor = [UIColor whiteColor];
    [blackView setTag:99999992];
    [blackView setBackgroundColor:[UIColor clearColor]];
    [self.view insertSubview:blackView belowSubview:self.photoImageView];
    [self.view insertSubview:whiteCaption aboveSubview:blackView];
    
    //hide quotes if appropriate
    if (self.post.caption.length) self.whiteCaption.hidden = NO;
    else self.whiteCaption.hidden = YES;
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9]];
                         self.whiteCaption.frame = CGRectMake(0,(self.screenHeight/2)+140,self.screenWidth,self.whiteCaption.contentSize.height);
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

-(void)removeBlackView {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UIView *blackView = [self.view viewWithTag:99999992];
    [UIView animateWithDuration:0.5
                     animations:^{
                         [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0]];
                         self.whiteCaption.frame = CGRectMake(0,self.screenHeight,self.screenWidth,self.captionTextView.contentSize.height);
                     }
                     completion:^(BOOL finished){
                         [blackView removeFromSuperview];
                         
                     }];
}

-(IBAction)expandImage:(id)sender {
    float halfScreenHeight = self.view.bounds.size.height/2;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsEnlargePhoto]) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self makeBlackView];
        [UIView animateWithDuration:0.35
                          delay:0.0
                        options: UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.photoImageView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
                         self.photoImageView.layer.shadowOffset = CGSizeMake(0, 1);
                         self.photoImageView.layer.shadowOpacity = 0;
                         self.photoImageView.layer.shadowRadius = 0;
                         self.photoImageView.clipsToBounds = NO;
                         [self.photoImageView setFrame:CGRectMake(0,halfScreenHeight-160,320,320)];
                         self.photoButton.frame = CGRectMake(0,0,self.screenWidth,self.screenHeight);
                         [self.view addSubview:self.photoImageView];
                         [self.view addSubview:self.photoButton];
                     }
                     completion:^(BOOL finished){
                         [[NSUserDefaults standardUserDefaults] setBool:false
                                                                 forKey:kDefaultsEnlargePhoto];
                         [self.view addGestureRecognizer:doubleTap];
                         doubleTap.enabled = YES;
                         self.photoImageViewY = self.photoImageView.frame.origin.y;
                         self.photoImageViewX = 0;
                     }];
    } else {
        [self.photoImageView setFrame:CGRectMake(0-self.photoImageViewX,self.photoImageViewY-20,self.photoImageView.frame.size.width,self.photoImageView.frame.size.height)];
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options: UIViewAnimationCurveEaseInOut
                         animations:^{
                             self.photoImageView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
                             self.photoImageView.layer.shadowOffset = CGSizeMake(0, 1);
                             self.photoImageView.layer.shadowOpacity = 1;
                             self.photoImageView.layer.shadowRadius = 3.0;
                             self.photoImageView.clipsToBounds = NO;
                             [self.photoImageView setFrame:CGRectMake(5,5,310,310)];
                             [self.photoButton setFrame:CGRectMake(5,5,310,310)];
                             [self.tableHeaderView addSubview:self.photoImageView];
                             [self.tableHeaderView addSubview:self.photoButton];
                             [self.tableHeaderView insertSubview:self.posterButton aboveSubview:self.photoButton];
                             [self.navigationController setNavigationBarHidden:NO animated:YES];
                         }
         
                         completion:^(BOOL finished){
                             [[NSUserDefaults standardUserDefaults] setBool:true
                                                                     forKey:kDefaultsEnlargePhoto];
                             doubleTap.enabled = NO;
                             [self.view removeGestureRecognizer:doubleTap];
                         }];
        [self.view addSubview:self.tableView];
        [self removeBlackView];
    }
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    self.photoImageViewX = scrollView.contentOffset.x;
}

- (void)zoomPhoto:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        UIScrollView *zoomPhotoScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,self.screenWidth, self.screenHeight)];
        [zoomPhotoScroll setContentSize:CGSizeMake(self.screenHeight,self.screenHeight)];
        zoomPhotoScroll.delegate = self;
        [zoomPhotoScroll setScrollEnabled:YES];
        [zoomPhotoScroll setShowsHorizontalScrollIndicator:NO];
        
        [self.view addSubview:zoomPhotoScroll];
        [zoomPhotoScroll addSubview:self.photoImageView];
        [zoomPhotoScroll addSubview:self.photoButton];
        [UIView animateWithDuration:0.3
                          delay:0.0
                        options: UIViewAnimationCurveLinear
                     animations:^{
                         [self.photoImageView setFrame:CGRectMake(0,0,self.screenHeight,self.screenHeight)];
                         [self.photoButton setFrame:CGRectMake(0,0,self.screenHeight,self.screenHeight)];
                         
                     }
                     completion:^(BOOL finished){
                         [[NSUserDefaults standardUserDefaults] setBool:false
                                                                 forKey:kDefaultsEnlargePhoto];
                         self.photoImageViewY = self.photoImageView.frame.origin.y;
                         [self.view removeGestureRecognizer:doubleTap];
                     }];
    } 
}

#pragma mark - Display likers

- (void)showLikers {
    NSDictionary *likers = self.post.likers;
    self.likersScrollView.delegate = self;
    [self.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.likersScrollView.showsHorizontalScrollIndicator=NO;
    
    float imageSize = 36.0;
    float space = 10.0;
    int index = 0;
    
    for (NSDictionary *liker in likers) {
        UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedLikeButtonRed.png"]];
        UIImageView *likerView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.likersScrollView.frame.origin.x)+((space+imageSize)*index)),(self.likersScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *likerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
        likerButton.titleLabel.text = [liker objectForKey:@"facebook_id"];
        likerButton.titleLabel.hidden = YES;
        
        //[likerButton setTag: [[liker objectForKey:@"facebook_id"] integerValue]];
        [likerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
        [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[liker objectForKey:@"facebook_id"]]];
        //[likerView setUserId:[liker objectForKey:@"facebook_id"]];
        likerView.userInteractionEnabled = YES;
        likerView.clipsToBounds = YES;
        likerView.layer.cornerRadius = 5.0;
        likerView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
        heart.frame = CGRectMake((((space+imageSize)*index)+22),18,20,20);
        [likerButton setFrame:likerView.frame];
        heart.clipsToBounds = NO;
        [self.likersScrollView addSubview:likerView];
        [self.likersScrollView addSubview:heart];
        [self.likersScrollView addSubview:likerButton];
        index++;
    }
    [self.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    [self.view bringSubviewToFront:self.likersScrollView];
}

-(void)profileTappedFromLikers:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}
#pragma mark - TableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return self.post.comments.count;
    } else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddComment"];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:66];
        imageView.layer.cornerRadius = 5.0f;
        imageView.clipsToBounds = YES;
        [imageView setImageWithURL:[Utilities profileImageURLForCurrentUser]];
        return cell;
    }
    
    static NSString *CellIdentifier = @"CommentCell";
    FDCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FDCommentCell" owner:self options:nil] lastObject];
    }
    UIButton *commenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    FDComment *comment = [self.comments objectAtIndex:indexPath.row];
    [cell configureForComment:comment];
    cell.profileImageView.layer.cornerRadius = 5.0;
    commenterButton.titleLabel.text = comment.user.facebookId;
    commenterButton.titleLabel.hidden = YES;
    self.commenterFacebookId = comment.user.facebookId;
    commenterButton.frame = cell.cellPhotoRect;
    [commenterButton addTarget:self action:@selector(profileTappedFromComment:) forControlEvents:UIControlEventTouchUpInside];
    [cell addSubview:commenterButton];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 50.f;
    else {
        FDComment *comment = [self.comments objectAtIndex:indexPath.row];
        return [FDCommentCell heightForComment:comment];
    }
}

#pragma mark - UITextViewDelegate Methods

- (void)willShowKeyboard {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"CANCEL"];
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.contentOffset = CGPointMake(0, (self.tableView.tableHeaderView.frame.size.height/1.5));
        [[self navigationItem] setRightBarButtonItem:cancelButton];
    } completion:^(BOOL finished) {
        self.tableView.scrollEnabled = YES;

    }];
}

-(void)doneEditing {
    [[self view] endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderAddCommentPrompt]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [textView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.contentOffset = CGPointZero;
    }];
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        textView.text = kPlaceholderAddCommentPrompt;
        textView.textColor = [UIColor lightGrayColor];
        textView.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
    }
}
- (void)willHideKeyboard {
    self.tableView.scrollEnabled = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textView.text.length) {
        [[FDAPIClient sharedClient] addCommentWithBody:textView.text forPost:self.post success:^(id result) {
            textView.text = nil;
            self.post = result;
            [self showComments];
        } failure:^(NSError *error) {
            NSLog(@"error posting comment! %@", error.description);
        }];
        }
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)viewDidUnload {
    [self setLikersScrollView:nil];
    [self setCaptionTextView:nil];
    [super viewDidUnload];
}

@end
