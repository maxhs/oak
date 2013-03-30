//
//  FDLoginViewController.m
//  foodia
//
//  Created by Max Haines-Stileson 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDLoginViewController.h"
#import "Constants.h"
#import "Facebook.h"
#import "FDAPIClient.h"
#import "Utilities.h"
#import "FDAPIClient.h"
#import "FDPost.h"
#import "FDPreviewPostView.h"
#import "FDEmailConnectViewController.h"
#import "FDUser.h"

static NSArray *tagLines;

@interface FDLoginViewController () <UIScrollViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *previewScrollView;
@property (nonatomic, retain) NSArray *previewPosts;
@property (nonatomic, retain) NSTimer *previewTimer;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *emailContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *signupEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *loginEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelEmailButton;

@end

@implementation FDLoginViewController

+ (void)initialize {
    if (self == [FDLoginViewController class]) {
        tagLines = @[
        @"Inspired by food",
        @"Remember the great moments",
        @"Discover new food, curated by folks you trust",
        @"Recommend great food to your friends",
        @"Spend less time with your phone…",
        @"…and more time with your food."];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.loginButton.alpha = 0.0f;
    self.loginButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.loginButton.layer.shadowOffset = CGSizeMake(0,0);
    self.loginButton.layer.shadowOpacity = .2;
    self.loginButton.layer.shadowRadius = 2.0;
    self.emailButton.alpha = 0.0f;
    self.emailButton.layer.cornerRadius = 5.0f;
    //self.emailButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
    //self.emailButton.layer.borderWidth = 1.0;
    //self.emailButton.clipsToBounds = YES;
    //[self.emailButton setBackgroundColor:[UIColor whiteColor]];
    self.emailButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.emailButton.layer.shadowOffset = CGSizeMake(0,0);
    self.emailButton.layer.shadowOpacity = .4;
    self.emailButton.layer.shadowRadius = 1.0;
    
    [self.passwordTextField setSecureTextEntry:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.loginButton.showsTouchWhenHighlighted = YES;
    [self.loginEmailButton addTarget:self action:@selector(connectWithEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.signupEmailButton addTarget:self action:@selector(signupWithEmail) forControlEvents:UIControlEventTouchUpInside];
    if (self.previewPosts.count == 0) [self loadPreviewPosts];
    [UIView animateWithDuration:0.5f animations:^{
        self.loginButton.alpha = 1.f;
        [self.emailButton setAlpha:1.0f];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate openSessionWithAllowLoginUI:NO];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        NSLog(@"logging in with NON-fb id");
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } else {
        [UIView animateWithDuration:0.5f animations:^{
            self.loginButton.alpha = 1.f;
        }];
        [FBSession.activeSession close]; // so we close our session and start over
    }
}

- (IBAction)showEmailConnect {
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, 0, 320, 200)];
        [self.logoImageView setAlpha:0.0];
        [self.previewScrollView setAlpha:0.25];
        if ([UIScreen mainScreen].bounds.size.height == 568){
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 30);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,20);
        } else {
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 20);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,10);
        }
     
    } completion:^(BOOL finished) {
       
    }];
}

- (IBAction)cancelEmailConnect {
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, -200, 320, 200)];
        [self.logoImageView setAlpha:1.0];
        [self.view endEditing:YES];
        [self.previewScrollView setAlpha:1.0];
        self.previewScrollView.transform = CGAffineTransformIdentity;
        self.pageControl.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void) signupWithEmail {
    [[FDAPIClient sharedClient] connectUser:self.emailTextField.text password:self.passwordTextField.text signup:YES success:^(FDUser *user) {
        NSLog(@"new user email: %@",user.email);
        NSLog(@"new user id: %@",user.userId);
        [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
        [[NSUserDefaults standardUserDefaults] setObject:user.userId forKey:kUserDefaultsId];
        FDEmailConnectViewController *vc;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
            vc = [storyboard5 instantiateViewControllerWithIdentifier:@"EmailConnect"];
        } else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            vc = [storyboard instantiateViewControllerWithIdentifier:@"EmailConnect"];
        }
        [vc setUser:user];
        [self presentViewController:vc animated:YES completion:nil];
    } failure:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while attempting to sign you up." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void) connectWithEmail {
    [[FDAPIClient sharedClient] connectUser:self.emailTextField.text password:self.passwordTextField.text signup:NO success:^(FDUser *user) {
        NSLog(@"connect with email result from login vc: %@",user.email);
        [[NSUserDefaults standardUserDefaults] setObject:user.authenticationToken forKey:kUserDefaultsAuthenticationToken];
        [[NSUserDefaults standardUserDefaults] setObject:user.avatarUrl forKey:kUserDefaultsAvatarUrl];
        [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } failure:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Those login details didn't work. Please try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (void)viewDidUnload
{
    [self setLoginButton:nil];
    [self setPreviewScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self stopPreviewTimer];
    
    // fade in the labels as they approach the center of the screen
    for (FDPreviewPostView *view in scrollView.subviews) {
        CGFloat distanceFromCenterScreen = fabs(view.center.x - scrollView.frame.size.width/2 - scrollView.contentOffset.x);
        CGFloat opacity = 1 - fabs(MIN(200.0,distanceFromCenterScreen)/200.0);
        view.taglineLabel.alpha = opacity;
        view.timeLabel.alpha = opacity;
        view.locationLabel.alpha = opacity;
    }
    
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self startPreviewTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) [self startPreviewTimer];
}

#pragma mark - Private Methods

- (void)loadPreviewPosts {
    self.previewScrollView.alpha = 0.0;
    [[FDAPIClient sharedClient] getFeaturedPostsSuccess:^(NSArray *posts) {
        self.previewPosts = [posts subarrayWithRange:NSMakeRange(0, MIN(posts.count, 6))];
        [self showPreview];
    } failure:^(NSError *error) {

    }];
}

- (void)showPreview {
    
    CGSize viewSize;
    
    [self.previewScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (FDPost *post in self.previewPosts) {
        NSUInteger index = [self.previewPosts indexOfObject:post];
        FDPreviewPostView *view = [[[NSBundle mainBundle] loadNibNamed:@"FDPreviewPostView" owner:self options:nil] lastObject];
        
        CGRect frame = CGRectMake(index * view.frame.size.width, 0, view.frame.size.width, view.frame.size.height);
        view.frame = frame;
        viewSize = frame.size;
        FDPost *post = [self.previewPosts objectAtIndex:index];
        [view.photoView setImageWithURL:post.feedImageURL];
        CGPathRef path = [UIBezierPath bezierPathWithRect:view.photoView.bounds].CGPath;
        [view.photoView.layer setShadowPath:path];
        view.photoView.layer.shouldRasterize = YES;
        // Don't forget the rasterization scale
        // I spent days trying to figure out why retina display assets weren't working as expected
        view.photoView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        view.photoView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        view.photoView.layer.shadowOffset = CGSizeMake(0, 1);
        view.photoView.layer.shadowOpacity = 1;
        view.photoView.layer.shadowRadius = 5.0;
        view.photoView.clipsToBounds = NO;

        [view.taglineLabel setText:[tagLines objectAtIndex:index]];
        [view.timeLabel setText:[Utilities timeIntervalSinceStartDate:post.postedAt]];
        if (post.locationName.length)
            view.locationLabel.text = [NSString stringWithFormat:@"At %@", post.locationName];
        else
            view.locationLabel.text = nil;
        [view setBackgroundColor:[UIColor clearColor]];
        [self.previewScrollView addSubview:view];
        [self.previewScrollView setBackgroundColor:[UIColor clearColor]];
    }
    
    self.previewScrollView.contentSize = CGSizeMake(self.previewPosts.count * self.previewScrollView.frame.size.width, self.previewScrollView.frame.size.height);
    [UIView animateWithDuration:0.75f animations:^{
        self.previewScrollView.alpha = 1.f;
    } completion:^(BOOL finished) {
        [self startPreviewTimer];
    }];
}

- (void)startPreviewTimer {
    self.previewTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(showNextPreview) userInfo:nil repeats:NO];
}

- (void)stopPreviewTimer {
    [self.previewTimer invalidate];
    self.previewTimer = nil;
}

- (void)showNextPreview {
    NSUInteger currentIndex = floor(_previewScrollView.contentOffset.x/_previewScrollView.frame.size.width);
    
    if (currentIndex == 5) {
    // go back to first preview
        
        [UIView animateWithDuration:0.75 animations:^{
            _previewScrollView.alpha = 0.f;
        } completion:^(BOOL finished) {
            _previewScrollView.contentOffset = CGPointZero;
            [UIView animateWithDuration:0.75 animations:^{
                _previewScrollView.alpha = 1.0;
            } completion:^(BOOL finished) {
                [self startPreviewTimer];
            }];
        }];
    } else {
        CGFloat newOffsetX = (currentIndex + 1) * _previewScrollView.frame.size.width;
        [UIView animateWithDuration:0.75 animations:^{
            _previewScrollView.contentOffset = CGPointMake(newOffsetX, 0);
        } completion:^(BOOL finished) {
            [self startPreviewTimer];
            [self loginFailed];
        }];
    }
}

- (IBAction)login:(id)sender {
    [UIView animateWithDuration:0.3f animations:^{
        [self.loginButton setAlpha: 0.f];
        [self.emailButton setAlpha:0.f];
    }];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate openSessionWithAllowLoginUI:YES];
}

- (void)loginFailed {
    [UIView animateWithDuration:0.5f animations:^{
        [self.loginButton setAlpha:1.0f];
        [self.emailButton setAlpha:1.0f];
    }];
}

@end
