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
#import "FDEditProfileViewController.h"
#import "FDUser.h"

static NSArray *tagLines;

@interface FDLoginViewController () <UIScrollViewDelegate, UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *previewScrollView;
@property (nonatomic, retain) NSArray *previewPosts;
@property (nonatomic, retain) NSTimer *previewTimer;
@property (weak, nonatomic) IBOutlet UIImageView *nameBackground;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *emailContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *signupEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *loginEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelEmailButton;
@property BOOL emailLoginStarted;
@end

@implementation FDLoginViewController

@synthesize emailLoginStarted = _emailLoginStarted;

+ (void)initialize {
    if (self == [FDLoginViewController class]) {
        tagLines = @[
        @"Capture and share your great food moments",
        @"Discover new food, curated by folks you trust",
        @"Recommend great food to your friends",
        @"Find inspiration through food",
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
    self.emailButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.emailButton.layer.shadowOffset = CGSizeMake(0,0);
    self.emailButton.layer.shadowOpacity = .2;
    self.emailButton.layer.shadowRadius = 2.0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.emailButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
        [self.signupEmailButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:17.0]];
        [self.loginEmailButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:17.0]];
        [self.nameTextField setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
        [self.emailTextField setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
        [self.passwordTextField setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
        [self.forgotPasswordButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
    }

    [self.signupEmailButton setBackgroundColor:[UIColor whiteColor]];
    self.signupEmailButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.signupEmailButton.layer.shadowOffset = CGSizeMake(0,0);
    self.signupEmailButton.layer.shadowOpacity = .2;
    self.signupEmailButton.layer.shadowRadius = 3.0;
    
    [self.loginEmailButton setBackgroundColor:[UIColor whiteColor]];
    self.loginEmailButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.loginEmailButton.layer.shadowOffset = CGSizeMake(0,0);
    self.loginEmailButton.layer.shadowOpacity = .2;
    self.loginEmailButton.layer.shadowRadius = 3.0;
    [self.passwordTextField setSecureTextEntry:YES];
    self.loginButton.showsTouchWhenHighlighted = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.signupEmailButton addTarget:self action:@selector(showSignup) forControlEvents:UIControlEventTouchUpInside];
    [self.loginEmailButton addTarget:self action:@selector(showLogin) forControlEvents:UIControlEventTouchUpInside];
    [UIView animateWithDuration:0.5f animations:^{
        self.loginButton.alpha = 1.f;
        self.emailButton.alpha = 1.f;
    }];
    if (self.previewPosts.count == 0) [self loadPreviewPosts];
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate openSessionWithAllowLoginUI:NO];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthenticationToken] && [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAvatarUrl] length]) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self performSegueWithIdentifier:@"ShowFeed" sender:self];
    } else {
        
        [FBSession.activeSession close]; // so we close our session and start over
    }
    [super viewWillAppear:animated];
}

- (IBAction)showEmailConnect {
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.signupEmailButton setAlpha:1.0];
        [self.loginEmailButton setAlpha:1.0];
        [self.logoImageView setAlpha:0.0];
        [self.previewScrollView setAlpha:0.2];
        [self.pageControl setAlpha:0.2];
        [self.cancelEmailButton setAlpha:1.0];
        [self.loginButton setAlpha:0.2];
     
    } completion:^(BOOL finished) {
        self.emailLoginStarted = YES;
        //ensure user has no legacy info
        self.signupEmailButton.transform = CGAffineTransformIdentity;
        self.loginEmailButton.transform = CGAffineTransformIdentity;
        [FBSession.activeSession closeAndClearTokenInformation];
        [NSUserDefaults resetStandardUserDefaults];
        [NSUserDefaults standardUserDefaults];
        NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
        
        [self.emailButton removeTarget:self action:@selector(showEmailConnect) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (IBAction)cancelEmailConnect {
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, -200, 320, 200)];
        [self.logoImageView setAlpha:1.0];
        [self.signupEmailButton setAlpha:0.0];
        self.signupEmailButton.transform = CGAffineTransformIdentity;
        [self.loginEmailButton setAlpha:0.0];
        self.loginEmailButton.transform = CGAffineTransformIdentity;
        [self.view endEditing:YES];
        [self.previewScrollView setAlpha:1.0];
        [self.pageControl setAlpha:1.0];
        self.previewScrollView.transform = CGAffineTransformIdentity;
        self.pageControl.transform = CGAffineTransformIdentity;
        [self.cancelEmailButton setAlpha:0.0];
        [self.loginButton setAlpha:1.0];
        [self.forgotPasswordButton setAlpha:0.0];
    } completion:^(BOOL finished) {
        self.emailLoginStarted = NO;
        [self.signupEmailButton removeTarget:self action:@selector(signupWithEmail) forControlEvents:UIControlEventTouchUpInside];
        [self.loginEmailButton removeTarget:self action:@selector(connectWithEmail) forControlEvents:UIControlEventTouchUpInside];
        [self.signupEmailButton addTarget:self action:@selector(showSignup) forControlEvents:UIControlEventTouchUpInside];
        [self.loginEmailButton addTarget:self action:@selector(showLogin) forControlEvents:UIControlEventTouchUpInside];
        [self.emailButton addTarget:self action:@selector(showEmailConnect) forControlEvents:UIControlEventTouchUpInside];
        [self.nameTextField setHidden:NO];
        [self.nameBackground setHidden:NO];
    }];
}


- (void)showSignup {
    [self.forgotPasswordButton setHidden:YES];
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, 0, 320, 200)];
        [self.loginEmailButton setAlpha:0.0];
        if ([UIScreen mainScreen].bounds.size.height == 568) {
            self.signupEmailButton.transform = CGAffineTransformMakeTranslation(60, 94);
        } else {
            self.signupEmailButton.transform = CGAffineTransformMakeTranslation(60, 90);
        }
        if ([UIScreen mainScreen].bounds.size.height == 568){
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 40);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,40);
        } else {
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 45);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,45);
        }
     
    } completion:^(BOOL finished) {
        [self.signupEmailButton addTarget:self action:@selector(signupWithEmail) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)showLogin {
    [self.forgotPasswordButton setHidden:NO];
    [self.nameTextField setHidden:YES];
    [self.nameBackground setHidden:YES];
    [UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.emailContainerView setFrame:CGRectMake(0, -30, 320, 200)];
        [self.signupEmailButton setAlpha:0.0];
        if ([UIScreen mainScreen].bounds.size.height == 568) {
            self.loginEmailButton.transform = CGAffineTransformMakeTranslation(-60, 92);
        } else {
            self.loginEmailButton.transform = CGAffineTransformMakeTranslation(-60, 86);
            self.forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, 20);
        }
        if ([UIScreen mainScreen].bounds.size.height == 568){
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 40);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,40);
        } else {
            self.previewScrollView.transform = CGAffineTransformMakeTranslation(0, 45);
            self.pageControl.transform = CGAffineTransformMakeTranslation(0,45);
        }
        [self.forgotPasswordButton setAlpha:1.0];
    } completion:^(BOOL finished) {
        [self.loginEmailButton addTarget:self action:@selector(connectWithEmail) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (IBAction)forgotPassword {
    UIAlertView *forgotPassword = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Please enter your email address:" delegate:self cancelButtonTitle:@"Submit" otherButtonTitles:@"Cancel",nil];
    forgotPassword.alertViewStyle = UIAlertViewStylePlainTextInput;
    [forgotPassword show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Okay"] || [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } else {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [[FDAPIClient sharedClient] forgotPassword:[[alertView textFieldAtIndex:buttonIndex] text] success:^(id result) {
            [[[UIAlertView alloc]  initWithTitle:@"Phew!" message:@"We successfully reset your password. Please check your email for the new one." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        } failure:^(NSError *error) {
            [[[UIAlertView alloc]  initWithTitle:@"Huh?" message:@"Sorry, but we couldn't find an account for that email address." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
            NSLog(@"failure! %@",error.description);
        }];
    }
    
}

- (void)signupWithEmail {
    if (self.emailTextField.text.length && self.passwordTextField.text.length && self.nameTextField.text.length){
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self.view endEditing:YES];
        [[FDAPIClient sharedClient] connectUser:self.nameTextField.text email:self.emailTextField.text password:self.passwordTextField.text signup:YES fbid:nil success:^(FDUser *user) {
            [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [[NSUserDefaults standardUserDefaults] setObject:user.name forKey:kUserDefaultsUserName];
            [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
            [[NSUserDefaults standardUserDefaults] setObject:user.userId forKey:kUserDefaultsId];
            [[NSUserDefaults standardUserDefaults] setObject:user.password forKey:kUserDefaultsPassword];
            FDEditProfileViewController *vc;
            if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
                UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
                vc = [storyboard5 instantiateViewControllerWithIdentifier:@"EditProfile"];
            } else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
                vc = [storyboard instantiateViewControllerWithIdentifier:@"EditProfile"];
            }
            [vc setUser:user];
            [self presentViewController:vc animated:YES completion:nil];
        } failure:^(NSError *error) {
            [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But it looks like there's already an existing account for that email address. Try logging in instead." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Please make sure you've filled out all the fields before continuing" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void) connectWithEmail {
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self.view endEditing:YES];
    [[FDAPIClient sharedClient] connectUser:nil email:self.emailTextField.text password:self.passwordTextField.text signup:NO fbid:nil success:^(FDUser *user) {
            [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        if (user.avatarUrl.length) {
            [[NSUserDefaults standardUserDefaults] setObject:user.avatarUrl forKey:kUserDefaultsAvatarUrl];
            [[NSUserDefaults standardUserDefaults] setObject:user.authenticationToken forKey:kUserDefaultsAuthenticationToken];
            [[NSUserDefaults standardUserDefaults] setObject:user.email forKey:kUserDefaultsEmail];
            [self performSegueWithIdentifier:@"ShowFeed" sender:self];
        } else {
            FDEditProfileViewController *vc;
            if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
                UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
                vc = [storyboard5 instantiateViewControllerWithIdentifier:@"EditProfile"];
            } else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
                vc = [storyboard instantiateViewControllerWithIdentifier:@"EditProfile"];
            }
            [vc setUser:user];
            [self presentViewController:vc animated:YES completion:nil];
        }
        
    } failure:^(NSError *error) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Those credentials didn't work. Please try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
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
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
            [view.taglineLabel setFont:[UIFont fontWithName:kFuturaMedium size:17.0]];
            [view.timeLabel setFont:[UIFont fontWithName:kFuturaMedium size:14.0]];
            [view.locationLabel setFont:[UIFont fontWithName:kFuturaMedium size:14.0]];
        }
        CGRect frame = CGRectMake(index * view.frame.size.width, 0, view.frame.size.width, view.frame.size.height);
        view.frame = frame;
        viewSize = frame.size;
        FDPost *post = [self.previewPosts objectAtIndex:index];
        [view.photoView setImageWithURLRequest:[NSURLRequest requestWithURL:post.feedImageURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [UIView animateWithDuration:.75f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [view.photoView setImage:image];
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
            }completion:^(BOOL finished) {
                
            }];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
        }];
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
        self.pageControl.alpha = 1.f;
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
            if (self.emailLoginStarted){
                [UIView animateWithDuration:0.75 animations:^{
                    _previewScrollView.alpha = .2;
                } completion:^(BOOL finished) {
                    [self startPreviewTimer];
                }];
            } else {
                [UIView animateWithDuration:0.75 animations:^{
                    _previewScrollView.alpha = 1.0;
                } completion:^(BOOL finished) {
                    [self startPreviewTimer];
                }];
            }
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
    if (!self.emailLoginStarted){
        [UIView animateWithDuration:0.5f animations:^{
            [self.loginButton setAlpha:1.0f];
            [self.emailButton setAlpha:1.0f];
        }];
    }
}

@end
