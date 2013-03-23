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
@property (weak, nonatomic) IBOutlet UIButton *submitEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelEmailButton;

@end

@implementation FDLoginViewController

+ (void)initialize {
    if (self == [FDLoginViewController class]) {
        tagLines = @[
        @"A food journal you can share",
        @"Discover new food, curated by folks you trust",
        @"Remember those great food moments",
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
    self.loginButton.layer.shadowOpacity = .4;
    self.loginButton.layer.shadowRadius = 1.0;
    self.emailButton.alpha = 0.0f;
    self.emailButton.layer.cornerRadius = 5.0f;
    self.emailButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
    self.emailButton.layer.borderWidth = 1.0;
    self.emailButton.clipsToBounds = YES;
    //[self.emailButton setBackgroundColor:[UIColor whiteColor]];
    self.emailButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.emailButton.layer.shadowOffset = CGSizeMake(0,0);
    self.emailButton.layer.shadowOpacity = .4;
    self.emailButton.layer.shadowRadius = 1.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.loginButton.showsTouchWhenHighlighted = YES;
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
    } else {
        [UIView animateWithDuration:0.5f animations:^{
            self.loginButton.alpha = 1.f;
        }];
        [FBSession.activeSession close]; // so we close our session and start over
    }
}

- (IBAction)showEmailConnect {
    /*FDEmailConnectViewController *vc;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        vc = [storyboard5 instantiateViewControllerWithIdentifier:@"EmailConnect"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        vc = [storyboard instantiateViewControllerWithIdentifier:@"EmailConnect"];
    }
    [self presentViewController:vc animated:YES completion:nil];*/
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, 0, 320, 200)];
        [self.logoImageView setAlpha:0.0];
    } completion:^(BOOL finished) {
       
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

        /*CGPathRef path2 = [UIBezierPath bezierPathWithRect:view.taglineLabel.bounds].CGPath;
        [view.taglineLabel.layer setShadowPath:path2];
        view.taglineLabel.layer.shouldRasterize = YES;
        view.taglineLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
        view.taglineLabel.layer.shadowColor = [UIColor whiteColor].CGColor;
        view.taglineLabel.layer.shadowOffset = CGSizeMake(0, -2);
        view.taglineLabel.layer.shadowOpacity = .7;
        view.taglineLabel.layer.shadowRadius = 10.0;
        view.taglineLabel.clipsToBounds = NO;*/

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
