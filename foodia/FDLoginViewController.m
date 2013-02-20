//
//  FDLoginViewController.m
//  foodia
//
//  Created by Max Haines-Stileson 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDLoginViewController.h"
#import "Facebook.h"
#import "FDAPIClient.h"
#import "Utilities.h"
#import "FDAPIClient.h"
#import "FDPost.h"
#import "FDPreviewPostView.h"

static NSArray *tagLines;

@interface FDLoginViewController () <UIScrollViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *previewScrollView;
@property (nonatomic, retain) NSArray *previewPosts;
@property (nonatomic, retain) NSTimer *previewTimer;

@end

@implementation FDLoginViewController

+ (void)initialize {
    if (self == [FDLoginViewController class]) {
        tagLines = @[
        @"Remember your amazing food moments",
        @"Discover new food, curated by folks you trust",
        @"Check in anywhere, anytime…",
        @"Recommend great food to your friends",
        @"Spend less time with your phone,\n and more time with your food…",
        @"…all from one, simple, easy to use app."];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.loginButton.alpha = 0.0f;
    self.loginButton.showsTouchWhenHighlighted = YES;
    if (self.previewPosts.count == 0) [self loadPreviewPosts];
    [UIView animateWithDuration:0.5f animations:^{
        self.loginButton.alpha = 1.f;
        self.loginButton.layer.shadowColor = [UIColor blackColor].CGColor;
        self.loginButton.layer.shadowOffset = CGSizeMake(0,0);
        self.loginButton.layer.shadowOpacity = .4;
        self.loginButton.layer.shadowRadius = 1.0;
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } else {
        [UIView animateWithDuration:0.5f animations:^{
            self.loginButton.alpha = 1.f;
        }];
    [FBSession.activeSession close]; // so we close our session and start over
    }
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
        self.loginButton.alpha = 0.f;
    }];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate openSessionWithAllowLoginUI:YES];
}

- (void)loginFailed {
    [UIView animateWithDuration:0.5f animations:^{
        self.loginButton.alpha = 1.0f;
    }];
}

@end
