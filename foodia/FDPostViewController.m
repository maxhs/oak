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
#import "Utilities.h"
#import "FDUser.h"
#import <QuartzCore/QuartzCore.h>
#import "FDCommentCell.h"
#import "FDProfileViewController.h"
#import "FDPlaceViewController.h"
#import "FDRecommendViewController.h"
#import "FDComment.h"
#import "Constants.h"
#import "FDPostTableViewController.h"
#import "FDSlidingViewController.h"
#import "Facebook.h"
#import <MessageUI/MessageUI.h>
#import "FDFoodiaTag.h"
#import "FDNewPostViewController.h"
#import "FDPostsTagsViewController.h"
#define kBlackviewTag 99999992

NSString *const kPlaceholderAddCommentPrompt = @"Add your two cents...";
static NSDictionary *placeholderImages;

@interface FDPostViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> {
    CGFloat lastScale;
    BOOL showingDetailImage;
    BOOL isHoldingPost;
    BOOL justLiked;
    float socialLabelHeight;
    CGRect captionRect;
    CGRect socialLabelRect;
    CGRect newTableHeaderView;
    CGRect screenRect;
    CGFloat screenWidth;
    CGFloat screenHeight;
}

@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackground;
@property (weak,nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *posterButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *recButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *recCountLabel;
@property (weak, nonatomic) IBOutlet UITextView *socialLabel;
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UITextView *whiteCaption;
@property (weak, nonatomic) IBOutlet UIView *tableHeaderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak,nonatomic) IBOutlet UILabel *postTitle;
@property (strong, nonatomic) FDComment *posterComment;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) FDPost *post;
@property (nonatomic, strong) NSArray *comments;
@property (weak, nonatomic) IBOutlet UIImageView *likeNotificationImageView;
@property (weak, nonatomic) IBOutlet UIView *likeNotificationContainer;
@property (strong, nonatomic) UIImageView *loadingOverlay;
@property (strong, nonatomic) UILabel *holdLabel;
@property (weak, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGesture;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UITapGestureRecognizer *oneTap;
@property (strong, nonatomic) UIBarButtonItem *editButton;

-(IBAction)handlePhotoPinch:(UIPinchGestureRecognizer*)pinchGesture;
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
@end

@implementation FDPostViewController

@synthesize likersScrollView, addComment, whiteCaption;
@synthesize post = _post;
@synthesize loadingOverlay = _loadingOverlay;
@synthesize holdLabel = _holdLabel;
@synthesize comments = _comments;
@synthesize shouldShowComment;

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
    [Flurry logEvent:@"ViewingPost" timed:YES];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1.0]];
    _holdLabel = [[UILabel alloc] init];
    _loadingOverlay = [[UIImageView alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"RefreshPostView" object:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:true
                                            forKey:kDefaultsEnlargePhoto];
    self.posterComment = [[FDComment alloc] init];
    screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.recButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:.4].CGColor;
    self.recButton.layer.borderWidth = 1.0f;
    self.recButton.backgroundColor = [UIColor clearColor];
    self.recButton.layer.cornerRadius = 17.0f;
    
    self.likeNotificationImageView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.likeNotificationImageView.layer.shadowOffset = CGSizeMake(0, 0);
    self.likeNotificationImageView.layer.shadowOpacity = 1;
    self.likeNotificationImageView.layer.shadowRadius = 20.0;
    
    //reframes the tableheader view if the user edits their post and the contentsize changes
    self.shouldReframe = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    if ([self.view viewWithTag:kBlackviewTag]){
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    [self.likeNotificationContainer setHidden:YES];
    self.oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandImage:)];
    self.oneTap.numberOfTapsRequired = 1;
    [self.oneTap setEnabled:YES];
    self.oneTap.delegate = self;
    [self.photoImageView addGestureRecognizer:self.oneTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToLike)];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTap setEnabled:YES];
    doubleTap.delegate = self;
    [self.photoImageView addGestureRecognizer:doubleTap];
    
    [self.oneTap requireGestureRecognizerToFail:doubleTap];
    
    UILongPressGestureRecognizer *pressAndHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(holdOntoPost)];
    [pressAndHold setEnabled:YES];
    pressAndHold.delegate = self;
    pressAndHold.minimumPressDuration = 0.3;
    [self.photoImageView addGestureRecognizer:pressAndHold];
    
    //[pressAndHold requireGestureRecognizerToFail:oneTap];
    
    // look for a cached detail version of this post
    // if none exists, load from the API
    /*FDPost *cachedPost = [FDCache getCachedPostForIdentifier:self.postIdentifier];
    if (cachedPost != nil) {
        NSLog(@"using cached post");
        self.post = cachedPost;
    } else */
    
    [self refresh];
    if (self.post != nil){
        [self showComments];
        [self showPostDetails];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! ([touch.view isKindOfClass:[UIControl class]]);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.post){
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.post forKey:@"post"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePostNotification" object:nil userInfo:userInfo];
    }
    //temporary comment out
    //[FDCache cachePost:self.post];
    //[FDCache cacheDetailPost:self.post];
    self.post = nil;
    self.postRequestOperation = nil;
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
        FDNewPostViewController *newPostVC = [segue destinationViewController];
        [newPostVC.postButtonItem setTitle:@"SAVE"];
        [newPostVC setIsEditingPost:YES];
        [FDPost setUserPost:self.post];
        [FDPost.userPost setPhotoImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:self.post.originalImageURL]]];
    } else if ([segue.identifier isEqualToString:@"Recommend"]) {
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound) {
            // No permissions found in session, ask for it
            [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                if (!error) {
                    if ([FBSession.activeSession.permissions
                         indexOfObject:@"publish_actions"] != NSNotFound) {
                        // If permissions granted, go to the rec controller
                        FDRecommendViewController *vc = [segue destinationViewController];
                        [vc setPost:self.post];
                    } else {
                        [self dismissViewControllerAnimated:YES completion:nil];
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we'll need your permission in order to post recommendations to Facebook." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                    }
                }
            }];
        } else if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] != NSNotFound) {
            FDRecommendViewController *vc = [segue destinationViewController];
            [vc setPost:self.post];
        }
    } else if ([segue.identifier isEqualToString:@"ShowProfile"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        [profileVC initWithUserId:self.post.user.userId];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromLikers"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        UIButton *button = (UIButton *) sender;
        [profileVC initWithUserId:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromComment"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        UIButton *button = (UIButton *) sender;
        [profileVC initWithUserId:button.titleLabel.text];
    } else if([segue.identifier isEqualToString:@"ShowPlaceFromPost"]) {
        FDPlaceViewController *vc = [segue destinationViewController];
        [vc setVenueId:self.post.foursquareid];
    } else if ([segue.identifier isEqualToString:@"ShowPostsForTag"]) {
        FDPostsTagsViewController *postsVC = segue.destinationViewController;
        UIButton *button = (UIButton *) sender;
        [postsVC setUniversal:YES];
        [postsVC setTagName:button.titleLabel.text];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self performSegueWithIdentifier:@"Recommend" sender:self];
    } else if(buttonIndex == 1) {
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",self.post.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self presentViewController:viewController animated:YES completion:nil];
        }
    } else if(buttonIndex == 2) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", self.post.foodiaObject, self.postIdentifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:self.post.foodiaObject];
            if (controller) [self presentViewController:controller animated:YES completion:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)refresh {
    [self.postRequestOperation cancel];
    self.postRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getDetailsForPostWithIdentifier:self.postIdentifier success:^(FDPost *post) {
        self.post = post;
        [self showPostDetails];
        [self showComments];
        self.locationButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.locationButton.layer.borderWidth = 1.0f;
        self.locationButton.layer.cornerRadius = 17.0f;
        [self.locationButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        if ([self.post.locationName isEqualToString:@""]){
            [self.locationButton setHidden:YES];
        } else {
            [self.locationButton setTitle:self.post.locationName forState:UIControlStateNormal];
        }
    } failure:^(NSError *error) {
        //NSLog(@"ERROR LOADING POST %@", error.description);
    }];
    //[self.postRequestOperation start];
}

- (void)showPostDetails {
    //Add en edit button if the post is editable
    if ([self.post.user.facebookId isEqualToString:[[NSUserDefaults standardUserDefaults]objectForKey:@"FacebookID"]] || [self.post.user.userId isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"EDIT" style:UIBarButtonItemStyleBordered target:self action:@selector(updatePost)];
    }
    if (self.post.user.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        [self.posterButton setImageWithURL:[Utilities profileImageURLForFacebookID:self.post.user.facebookId] forState:UIControlStateNormal];
    } else if (self.post.user.avatarUrl.length) {
        [self.posterButton setImageWithURL:[NSURL URLWithString:self.post.user.avatarUrl] forState:UIControlStateNormal];
    } else {
        //set from Amazon. risky...
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",self.post.user.userId]];
        [self.posterButton setImageWithURL:url forState:UIControlStateNormal];
    }

    self.posterButton.imageView.layer.cornerRadius = 25.0f;
    [self.posterButton.imageView setBackgroundColor:[UIColor clearColor]];
    [self.posterButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    [UIView animateWithDuration:.25 animations:^{
        [self.likeButton setAlpha:1.0];
        [self.likeCountLabel setAlpha:1.0];
        [self.likersScrollView setAlpha:1.0];
        [self.posterButton setAlpha:1.0];
    }];
    if (self.post.detailImageUrlString.length) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadWithURL:self.post.detailImageURL options:0 progress:^(NSUInteger receivedSize, long long expectedSize) {
            self.progressView.progress = (float)receivedSize/(float)expectedSize;
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (finished) {
                [self.photoImageView setImage:image];
                [UIView animateWithDuration:.25 animations:^{
                    [self.photoImageView setAlpha:1.0];
                    [self.photoBackground setAlpha:0.6];
                }];
                if (self.shouldShowComment) {
                    [self.addComment becomeFirstResponder];
                    self.shouldShowComment = NO;
                }
                self.navigationItem.rightBarButtonItem = self.editButton;
                [self.navigationItem.rightBarButtonItem setEnabled:YES];
            }
        }];
    } else {
        [self.photoImageView setImage:[FDPostViewController placeholderImageForCategory:self.post.category]];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.photoImageView setAlpha:1.0];
            [self.photoBackground setAlpha:0.6];
            [self.likeButton setAlpha:1.0];
            [self.likeCountLabel setAlpha:1.0];
            [self.likersScrollView setAlpha:1.0];
            
        }completion:^(BOOL finished) {
            self.navigationItem.rightBarButtonItem = self.editButton;
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            if (self.shouldShowComment) {
                [self.addComment becomeFirstResponder];
                self.shouldShowComment = NO;
            }
        }];
    }
    
    self.postTitle.text = [Utilities postedAt:self.post.postedAt];
    self.socialLabel.text   = self.post.detailString;
    self.captionTextView.text  = [NSString stringWithFormat:@"\"%@\"", self.post.caption];
    self.likeCountLabel.text = [NSString stringWithFormat:@"%@", self.post.viewCount];
    self.recCountLabel.text = [NSString stringWithFormat:@"%d", [self.post.recommendedTo count]];
    
    //set social label frame size
    if(CGRectIsEmpty(socialLabelRect) || self.shouldReframe) {
        socialLabelRect = self.socialLabel.frame;
        socialLabelRect.size.height = self.socialLabel.contentSize.height;
        self.socialLabel.frame = socialLabelRect;
    }
    //set caption/message height
    /*if (CGRectIsEmpty(captionRect) && self.post.caption.length){
        captionRect = self.captionTextView.frame;
        captionRect.size.height = self.captionTextView.contentSize.height;
        captionRect.origin.y += self.socialLabel.contentSize.height;
        self.captionTextView.frame = captionRect;
    } else if (!self.post.caption.length) {
        captionRect = self.captionTextView.frame;
        captionRect.size.height = 0;
        captionRect.origin.y += self.socialLabel.contentSize.height-12;
        self.captionTextView.frame = captionRect;
    }*/

    if (self.post.tagArray.count) {
        [self.tagsScrollView setHidden:NO];
        [self showTags];
    } else {
        [self.tagsScrollView setHidden:YES];
    }

    //set the tableHeaderView frame according to social label and caption
    if (CGRectIsEmpty(newTableHeaderView) || self.shouldReframe){
        newTableHeaderView = [self.tableHeaderView frame];
        if (self.shouldReframe) newTableHeaderView.size.height -= socialLabelHeight;
        [self.tableHeaderView setFrame:CGRectMake(newTableHeaderView.origin.x,
                                                   newTableHeaderView.origin.y,
                                                   newTableHeaderView.size.width,
                                                   newTableHeaderView.size.height+self.socialLabel.frame.size.height+self.tagsScrollView.contentSize.height+8)];
        socialLabelHeight = self.socialLabel.frame.size.height;
        [self.photoImageView setFrame:CGRectMake(5,5,310,310)];
        [self.posterButton setFrame:CGRectMake(267,3,50,50)];
    }
    
    //hide quotes if appropriate
    /*if (self.post.caption.length) self.captionTextView.hidden = NO;
    else self.captionTextView.hidden = YES;*/
    
    [self.likeButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
    if ([self.post isLikedByUser]) {
        [self.likeButton setTitle:@"NICE" forState:UIControlStateNormal];
        [self.likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
    } else {
        [self.likeButton setImage:[UIImage imageNamed:@"dark_smile"] forState:UIControlStateNormal];
        //[self.likeButton setTitle:@"Smile" forState:UIControlStateNormal];
        [self.likeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
    }
    self.likeButton.layer.shouldRasterize = YES;
    self.likeButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.tableView setTableHeaderView:self.tableHeaderView];
    [self showLikers];
    self.shouldReframe = NO;
}

- (void)showTags{
    int previousTagOriginX = 0;
    int previousTagButtonSize = 0;
    int tagScrollViewContentSize = 0;
    [self.tagsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (FDFoodiaTag *tag in self.post.tagArray){
        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tagButton addTarget:self action:@selector(showPostsForTag:) forControlEvents:UIControlEventTouchUpInside];
        [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
        [tagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [tagButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
        CGSize stringSize = [tagButton.titleLabel.text sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
        [tagButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [tagButton setFrame:CGRectMake(previousTagOriginX+previousTagButtonSize,0,stringSize.width+20,32)];
        previousTagButtonSize = tagButton.frame.size.width;
        tagScrollViewContentSize += previousTagButtonSize;
        previousTagOriginX = tagButton.frame.origin.x;
        [self.tagsScrollView addSubview:tagButton];
    }
    [self.tagsScrollView setContentSize:CGSizeMake(tagScrollViewContentSize,32)];
    [self.tagsScrollView setAlpha:1.0];
}

- (void)showPostsForTag:(UIButton*)tagButton {
    [self performSegueWithIdentifier:@"ShowPostsForTag" sender:tagButton];
}

- (void)showComments {
    self.comments = [self.post.comments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"epochTime" ascending:YES]]];
    [self.tableView reloadData];
}

- (IBAction)showPlace:(UIButton*)button {
    if ([button.titleLabel.text isEqualToString:@"Home"] || [button.titleLabel.text isEqualToString:@"home"]) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"We don't share information about anyone's home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self performSegueWithIdentifier:@"ShowPlaceFromPost" sender:nil];
    }
}

- (void)updatePost {
    [Flurry logEvent:@"EditPostTapped"];
    [self performSegueWithIdentifier:@"UpdatePost" sender:self.post];
}

- (IBAction)likeButtonTapped {
    /*if (self.post.isLikedByUser) {
        [UIView animateWithDuration:.35 animations:^{
            [self.likeButton setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
            //[self.likeButton setImage:[UIImage imageNamed:@"dark_smile"] forState:UIControlStateNormal];
        }];
        [Flurry logEvent:@"unlikeTapped"];
        [[FDAPIClient sharedClient] unlikePost:self.post
                                        detail:YES
                                       success:^(FDPost *newPost) {
                                           self.post = newPost;
                                           [self showPostDetails];
                                           [Flurry logEvent:@"unlikeSuccess"];
                                           self.justLiked = NO;
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }];
        [self refresh];
    } else {*/
        [Flurry logEvent:@"likeTapped"];
        [[FDAPIClient sharedClient] likePost:self.post
                                      detail:YES
                                     success:^(FDPost *newPost) {
                                         [Flurry logEvent:@"likeSuccess"];
                                         self.post = newPost;

                                         /*//conditionally change the like count number
                                         int t = [newPost.likeCount intValue] + 1;
                                         if (!self.justLiked) [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         self.justLiked = YES;*/

                                         [self showPostDetails];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }];
        [self refresh];
    //}
}
-(void)makeBlackView {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    self.slidingViewController.panGesture.enabled = NO;
    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    self.whiteCaption.text = self.captionTextView.text;
    self.whiteCaption.textAlignment = NSTextAlignmentCenter;
    self.whiteCaption.textColor = [UIColor whiteColor];
    [blackView setTag:kBlackviewTag];
    [blackView setBackgroundColor:[UIColor clearColor]];
    [self.view insertSubview:blackView belowSubview:self.photoImageView];
    [self.view insertSubview:self.whiteCaption aboveSubview:blackView];
    //[self.view insertSubview:self.foodiaObjectTextView aboveSubview:blackView];
    [self.view insertSubview:self.locationButton aboveSubview:blackView];

    //hide quotes if appropriate
    if (self.post.caption.length) self.whiteCaption.hidden = NO;
    else self.whiteCaption.hidden = YES;
    
    [UIView animateWithDuration:.3
                     animations:^{
                         [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9]];
                         if ([UIScreen mainScreen].bounds.size.height == 568){
                             self.whiteCaption.frame = CGRectMake(0,(screenHeight/2)+120,screenWidth,self.whiteCaption.contentSize.height);
                         } else {
                             self.whiteCaption.frame = CGRectMake(0,(screenHeight/2)+80,screenWidth,self.whiteCaption.contentSize.height);
                         }
                         //[self.foodiaObjectTextView setFrame:CGRectMake(0, 0, 320, 66)];
                         CGSize stringSize = [self.post.locationName sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
                         if (stringSize.width < 300.f){
                             [self.locationButton setFrame:CGRectMake(320-20-stringSize.width,screenHeight-40,stringSize.width+20,34)];
                         } else {
                             [self.locationButton setFrame:CGRectMake(0,screenHeight-40,300+20,34)];
                         }
                     }
                     completion:^(BOOL finished){

                     }];
}

-(void)removeBlackView {
    UIView *blackView = [self.view viewWithTag:kBlackviewTag];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                     animations:^{
                         [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0]];
                         self.whiteCaption.frame = CGRectMake(0,screenHeight,screenWidth,self.captionTextView.contentSize.height);
                         CGRect frame = CGRectMake(130,568,34,34);

                         [self.locationButton setFrame:frame];
                     }
                     completion:^(BOOL finished){
                         [self.navigationController setNavigationBarHidden:NO animated:YES];
                         [blackView removeFromSuperview];
                         self.slidingViewController.panGesture.enabled = YES;
                     }];
}

-(IBAction)expandImage:(id)sender {
    [Flurry logEvent:@"ExpandingImageFromPostView"];
    float halfScreenHeight = self.view.bounds.size.height/2;
    if (!showingDetailImage) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self makeBlackView];
        [UIView animateWithDuration:.1 animations:^{
            [self.photoBackground setAlpha:0.0];
        }];
        [UIView animateWithDuration:0.425
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [self.view addSubview:self.photoImageView];
                         [self.view addSubview:self.likeNotificationContainer];
                         if ([UIScreen mainScreen].bounds.size.height == 568) {
                             [self.photoImageView setFrame:CGRectMake(0,halfScreenHeight-170,320,320)];
                             [self.likeNotificationContainer setFrame:CGRectMake(110, 185, 100, 100)];
                         } else {
                             [self.photoImageView setFrame:CGRectMake(0,0,320,320)];
                         }
                     }
                     completion:^(BOOL finished){
                         showingDetailImage = YES;
                         [self.pinchGesture setEnabled:YES];
                         [self.panGesture setEnabled:YES];
                     }];
    } else {
        [UIView animateWithDuration:.20 delay:.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.photoBackground setAlpha:0.6];
        }completion:^(BOOL finished) {}];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.photoImageView.transform = CGAffineTransformIdentity;
                             [self.posterButton setAlpha:1.0];
                             [self.photoImageView setFrame:CGRectMake(5,5,310,310)];
                             [self.tableHeaderView addSubview:self.photoImageView];
                             [self.tableHeaderView addSubview:self.likeNotificationContainer];
                             [self.likeNotificationContainer setFrame:CGRectMake(110, 110, 100, 100)];
                             [self.tableHeaderView insertSubview:self.posterButton aboveSubview:self.photoImageView];
                             [self.tableHeaderView bringSubviewToFront:self.likeNotificationContainer];
                             [self removeBlackView];
                         }
         
                         completion:^(BOOL finished){
                             showingDetailImage = NO;
                             [self.pinchGesture setEnabled:NO];
                             [self.panGesture setEnabled:NO];
                             
                         }];
        [self.view addSubview:self.tableView];
    }
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    //self.photoImageViewX = scrollView.contentOffset.x;
    if (scrollView == self.likersScrollView) [Flurry logEvent:@"likersScrollViewDidScroll"];
}

#pragma mark - Display likers

- (void)showLikers {
    NSDictionary *viewers = self.post.viewers;
    //NSDictionary *likers = self.post.likers;
    self.likersScrollView.delegate = self;
    [self.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.likersScrollView.showsHorizontalScrollIndicator=NO;
    
    if ([self.post isLikedByUser]) {
        [self.likeButton setHidden:YES];
        [self.likersScrollView setFrame:CGRectMake(30, self.likersScrollView.frame.origin.y, 290, 40)];
        self.likeCountLabel.transform = CGAffineTransformMakeTranslation(-68, 0);
    }
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;

    for (NSDictionary *viewer in viewers) {
        
        if ([viewer objectForKey:@"id"] != [NSNull null]){
            //UIImageView *face = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light_smile"]];
            __weak UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [viewerButton setFrame:CGRectMake(((space+imageSize)*index),0,imageSize, imageSize)];
            
            //passing liker facebook id as a string instead of NSNumber so that it can hold more data. tricksy.
            viewerButton.titleLabel.text = [[viewer objectForKey:@"id"] stringValue];
            viewerButton.titleLabel.hidden = YES;
            
            [viewerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
            
            if ([[viewer objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                /*[viewerButton.imageView setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    [viewerButton setImage:image forState:UIControlStateNormal];*/
                [viewerButton setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
                //}];
            } else {
                /*[viewerButton.imageView setImageWithURL:[viewer objectForKey:@"avatar_url"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    [viewerButton setImage:image forState:UIControlStateNormal];
                }];*/
                [viewerButton setImageWithURL:[NSURL URLWithString:[viewer objectForKey:@"avatar_url"]] forState:UIControlStateNormal];
            }

            viewerButton.imageView.layer.cornerRadius = 17.0;
            [viewerButton.imageView setBackgroundColor:[UIColor clearColor]];
            [viewerButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
            viewerButton.imageView.layer.shouldRasterize = YES;
            viewerButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            //face.frame = CGRectMake((((space+imageSize)*index)+18),18,20,20);
            
            [self.likersScrollView addSubview:viewerButton];
            /*for (NSDictionary *liker in likers) {
                if ([[liker objectForKey:@"id"] isEqualToNumber:[viewer objectForKey:@"id"]]){
                    [self.likersScrollView addSubview:face];
                    break;
                }
            }*/
        }
    index++;
    }
    [self.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    [self.view bringSubviewToFront:self.likersScrollView];
    self.likersScrollView.layer.shouldRasterize = YES;
    self.likersScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

-(void)profileTappedFromLikers:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}
#pragma mark - TableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.post.caption.length > 0) return 3;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.numberOfSections == 3 && section == 2) {
        return self.post.comments.count;
    } else if (tableView.numberOfSections == 2 && section == 1) return self.post.comments.count;
    else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CommentCell";
    FDCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FDCommentCell" owner:self options:nil] lastObject];
    }
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddComment"];
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:imageButton];
        [imageButton setFrame:[(UIImageView *)[cell viewWithTag:66] frame]];
        [imageButton setImageWithURL:[Utilities profileImageURLForCurrentUser] forState:UIControlStateNormal];
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.cornerRadius = 20.0f;
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        
        self.addComment = (UITextView *)[cell viewWithTag:67];
        self.addComment.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.4].CGColor;
        self.addComment.layer.cornerRadius = 3.0f;
        self.addComment.layer.borderWidth = 0.5f;
        self.addComment.layer.shouldRasterize = YES;
        self.addComment.layer.rasterizationScale = [UIScreen mainScreen].scale;

        return cell;
    } else if (self.post.caption.length > 0 && indexPath.section == 1) {
        //the poster's 'comment'
        UIButton *commenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.posterComment setBody:self.post.caption];
        [self.posterComment setUser:self.post.user];
        [self.posterComment setEpochTime:self.post.epochTime];
        [cell configureForComment:self.posterComment];

        commenterButton.titleLabel.text = self.posterComment.user.userId;
        commenterButton.titleLabel.hidden = YES;
        [cell addSubview:commenterButton];
        //set user image
        if (self.posterComment.user.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
            
            [commenterButton setImageWithURL:[Utilities profileImageURLForFacebookID:self.posterComment.user.facebookId] forState:UIControlStateNormal];
        } else {
            //set from Amazon. risky...
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",self.posterComment.user.userId]];
            [commenterButton setImageWithURL:url forState:UIControlStateNormal];
        }
        
        //can't edit the poster comment!
        [cell.editButton setHidden:YES];
        
        commenterButton.imageView.layer.cornerRadius = 20.0;
        [commenterButton.imageView setBackgroundColor:[UIColor clearColor]];
        [commenterButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        commenterButton.imageView.layer.shouldRasterize = YES;
        commenterButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        //self.commenterFacebookId = self.posterComment.user.facebookId;
        [commenterButton setFrame:CGRectMake(8,11,40,40)];
        [commenterButton addTarget:self action:@selector(profileTappedFromComment:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        UIButton *commenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commenterButton setFrame:CGRectMake(8,11,40,40)];
        FDComment *comment = [self.comments objectAtIndex:indexPath.row];
        [cell configureForComment:comment];
        commenterButton.titleLabel.text = comment.user.userId;
        commenterButton.titleLabel.hidden = YES;
        [cell addSubview:commenterButton];
        
        if (comment.user.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
            [commenterButton setImageWithURL:[Utilities profileImageURLForFacebookID:comment.user.facebookId] forState:UIControlStateNormal];
        } else {
            //set from Amazon. risky...
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",comment.user.userId]];
            [commenterButton setImageWithURL:url forState:UIControlStateNormal];
        }
        commenterButton.imageView.layer.cornerRadius = 20.0;
        [commenterButton.imageView setBackgroundColor:[UIColor clearColor]];
        [commenterButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        commenterButton.imageView.layer.shouldRasterize = YES;
        commenterButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
       // self.commenterFacebookId = comment.user.facebookId;
        
        [commenterButton addTarget:self action:@selector(profileTappedFromComment:) forControlEvents:UIControlEventTouchUpInside];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 66.f;
    else if (self.post.caption.length > 0 && indexPath.section == 1) {
        return [self heightForPosterComment];
    }
    else {
        FDComment *comment = [self.comments objectAtIndex:indexPath.row];
        return [FDCommentCell heightForComment:comment];
    }
}

- (CGFloat)heightForPosterComment {
    CGSize bodySize = [self.post.caption sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:16] constrainedToSize:CGSizeMake(207, 100000)];
    return MAX(33 + bodySize.height + 5.f, 60.f);
}


#pragma mark - UITextViewDelegate Methods

- (void)willShowKeyboard:(NSNotification *)notification {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"CANCEL"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets;
    if ([UIScreen mainScreen].bounds.size.height == 568){
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+185.0, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+105.0, 0.0);
    }
    self.tableView.contentInset = contentInsets;
    //self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    /*CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.addComment.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, 0.0);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }*/
}

-(void)doneEditing {
    [[self view] endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView == self.addComment) {
        [self.oneTap setEnabled:NO];
    }
    
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderAddCommentPrompt]) {
        textView.text = @"";
        textView.textColor = [UIColor darkGrayColor];
    }
    self.tableView.scrollsToTop = NO;
    self.tableView.scrollEnabled = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    self.tableView.scrollEnabled = YES;
    self.tableView.scrollsToTop = NO;
    self.navigationItem.rightBarButtonItem = self.editButton;
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        textView.text = kPlaceholderAddCommentPrompt;
        textView.textColor = [UIColor lightGrayColor];
        textView.font = [UIFont fontWithName:kHelveticaNeueThin size:15];
    }
    if (textView == self.addComment) {
        [self.oneTap setEnabled:YES];
    }
}
- (void)willHideKeyboard {
    self.tableView.scrollEnabled = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textView.text.length) {
            [[FDAPIClient sharedClient] addCommentWithBody:textView.text forPost:self.post success:^(FDPost* result) {
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

#pragma mark - Gesture Recognizers

- (IBAction)handlePhotoPinch:(UIPinchGestureRecognizer *)pinchGesture {
    if([pinchGesture state] == UIGestureRecognizerStateBegan) {
        // Reset the last scale, necessary if there are multiple objects with different scales
        lastScale = [pinchGesture scale];
    }
    
    if ([pinchGesture state] == UIGestureRecognizerStateBegan ||
        [pinchGesture state] == UIGestureRecognizerStateChanged) {
        
        CGFloat currentScale = [[[pinchGesture view].layer valueForKeyPath:@"transform.scale"] floatValue];
        
        // Constants to adjust the max/min values of zoom
        const CGFloat kMaxScale = 2.0;
        const CGFloat kMinScale = 1.0;
        
        CGFloat newScale = 1 -  (lastScale - [pinchGesture scale]); // new scale is in the range (0-1)
        newScale = MIN(newScale, kMaxScale / currentScale);
        newScale = MAX(newScale, kMinScale / currentScale);
        CGAffineTransform transform = CGAffineTransformScale([[pinchGesture view] transform], newScale, newScale);
        [pinchGesture view].transform = transform;
        
        lastScale = [pinchGesture scale];  // Store the previous scale factor for the next pinch gesture call
    }
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    CGPoint center = recognizer.view.center;
    center.y += translation.y;
    center.x += translation.x;
    recognizer.view.center = center;
}

- (void)holdOntoPost {
    
    if (!isHoldingPost){
        [[FDAPIClient sharedClient] holdPost:self.postIdentifier];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        [self.loadingOverlay setFrame:CGRectMake(0,-20, width, height)];
        [self.loadingOverlay setImage:[UIImage imageNamed:@"overlay4"]];
        [self.loadingOverlay setAlpha:0.0];
        [self.view insertSubview:self.loadingOverlay aboveSubview:self.navigationController.navigationBar];
        [self.holdLabel setFrame:CGRectMake(width/2-40, height/2-70, 80,100)];
        [self.holdLabel setText:@"Keeping this post"];
        [self.holdLabel setTextAlignment:NSTextAlignmentCenter];
        [self.holdLabel setNumberOfLines:2];
        [self.holdLabel setFont:[UIFont fontWithName:kHelveticaNeueCondensedBold size:20]];
        [self.holdLabel setTextColor:[UIColor whiteColor]];
        [self.holdLabel setAlpha:0.0];
        [self.holdLabel setBackgroundColor:[UIColor clearColor]];

        [self.view addSubview:self.holdLabel];
        [UIView animateWithDuration:.4 animations:^{
            [self.loadingOverlay setAlpha:1.0];
            [self.holdLabel setAlpha:1.0];
        } completion:^(BOOL finished) {
            [self performSelector:@selector(removeHoldOverlay) withObject:nil afterDelay:1.75];
            isHoldingPost = YES;
        }];
    }
}

- (void) removeHoldOverlay {
    if (showingDetailImage){
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    };
    [UIView animateWithDuration:.4 animations:^{
        [self.loadingOverlay setAlpha:0.0];
        [self.holdLabel setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)tapToLike {
    [self.likeNotificationContainer setHidden:NO];
    if (!self.post.isLikedByUser){
        [self likeButtonTapped];
    }
    [UIView animateWithDuration:.25 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.likeNotificationImageView setAlpha:1.0];
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
        [self.likersScrollView setFrame:CGRectMake(30, self.likersScrollView.frame.origin.y, 290, 40)];
        [self.likeButton setAlpha:0.0];
        self.likeCountLabel.transform = CGAffineTransformMakeTranslation(-68, 0);
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideLikeNotificationView) withObject:nil afterDelay:1.5];
        [self.likeButton removeFromSuperview];
    }];
}

- (void)hideLikeNotificationView {
    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.likeNotificationImageView setAlpha:0.0];
    }completion:^(BOOL finished) {
        [self.likeNotificationContainer setHidden:YES];
    }];
    
}

- (void)viewDidUnload {
    [self setLikersScrollView:nil];
    [self setCaptionTextView:nil];
    [super viewDidUnload];
}

@end
