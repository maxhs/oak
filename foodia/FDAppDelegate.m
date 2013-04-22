//
//  FDAppDelegate.m
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDLoginViewController.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDCache.h"
#import "ECSlidingViewController.h"
#import "FDNewPostViewController.h"
#import "Flurry.h"
#import "FDProfileViewController.h"
#import "Utilities.h"
#import "FBRequest.h"
#import <MessageUI/MessageUI.h>
#import <Accounts/Accounts.h>
#import "Constants.h"
#import "GAI.h"
#define kFlurryAPIKey @"W5U7NXYMMQ8RJQR7WI9A"

@interface FDAppDelegate ()
@property (strong,nonatomic) UILabel *wallPost;
@property UIButton *tryReconnecting;
@property UILabel *noConnection;
@end

@implementation FDAppDelegate

@synthesize facebook, isTakingPhoto;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Yay FOODIA!
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self customizeAppearance];
    
    self.facebook.sessionDelegate = self;
    [self performSetup];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [Flurry startSession:kFlurryAPIKey];
    //[TestFlight takeOff:(@"13a30f1fa03141084d0983b4e6f3e04f_NjQ4NDkyMDEyLTAyLTI0IDE1OjExOjM4LjE1Mjg3Mg")];
    //[MagicalRecord setupCoreDataStackWithStoreNamed:@"FoodiaV2.sqlite"];
    [FDCache clearCache];
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    //[GAI sharedInstance].dispatchInterval = 20;
    // Optional: set debug to YES for extra debugging information.
    [GAI sharedInstance].debug = YES;
    // Create tracker instance.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-40164626-1"];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    return YES;
}

#pragma mark uncaughtExceptionHandler
void uncaughtExceptionHandler(NSException *exception) {
    [Flurry logError:exception.name message:exception.description exception:exception];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    [Flurry logEvent:@"Did Receive Remote Notification"];
    NSLog(@"just got a remote notification: %@",pushMessage);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [Flurry logEvent:@"Registered For Remote Notifications"];
    [[FDAPIClient sharedClient] setDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [Flurry logEvent:@"Rejected Remote Notifications"];
    NSLog(@"failed to register for remote notificaitons");
}

- (void)performSetup {
    //tests whether the device has a 4-inch display
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        self.window.rootViewController = [storyboard5 instantiateInitialViewController];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        self.window.rootViewController = [storyboard instantiateInitialViewController];
    }
    [self.window makeKeyAndVisible];
}

/*-(void)setupNoConnection{
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat backgroundWidth = screen.size.width*3/4;
    CGFloat backgroundHeight = screen.size.height/3;
    CGFloat backgroundX = (screen.size.width/2)-(backgroundWidth/2);
    CGFloat backgroundY = (screen.size.height/2)-(backgroundHeight/2);
    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(backgroundX, backgroundY, backgroundWidth, backgroundHeight)];
    [background setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.85]];
    background.layer.cornerRadius = 6.0f;
    
    self.noConnection = [[UILabel alloc] initWithFrame:CGRectMake(screen.size.width/5,screen.size.height*0.35,screen.size.width/5*3,screen.size.height/6)];
    self.noConnection.backgroundColor = [UIColor clearColor];
    self.noConnection.font = [UIFont fontWithName:kAvenirMedium size:18];
    self.noConnection.text = @"Sorry, but you'll need the internet to use FOODIA.";
    self.noConnection.textColor = [UIColor whiteColor];
    self.noConnection.textAlignment = NSTextAlignmentCenter;
    self.noConnection.numberOfLines = 3;
    
    self.tryReconnecting = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tryReconnecting setBackgroundColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.75]];
    self.tryReconnecting.layer.cornerRadius = 3.0f;
    [self.tryReconnecting setFrame:CGRectMake(screen.size.width*0.175,screen.size.height*0.55,screen.size.width*0.65,screen.size.height/16)];
    [self.tryReconnecting addTarget:self action:@selector(openSessionWithAllowLoginUI:) forControlEvents:UIControlEventTouchUpInside];
    self.tryReconnecting.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.tryReconnecting.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:20]];
    [self.tryReconnecting setTitle:@"TAP TO RETRY CONNECTION" forState:UIControlStateNormal];
    [self.window addSubview:background];
    [self.window addSubview:noConnection];
    [self.window addSubview:tryReconnecting];
    [self hideLoadingOverlay];
}*/

- (void)fbDidNotLogin:(BOOL)cancelled {
    if (cancelled){
        NSLog(@"user cancelled login process");
    } else {
        NSLog(@"didn't login for some reason");
    }
}

- (void)fbDidLogin {
    NSLog(@"user logged in");
}

- (void)fbDidLogout {
    NSLog(@"user logged out");
}

- (void)fbSessionInvalidated {
    NSLog(@"session was invalidated");
}

-(void)fbResync
{
    ACAccountStore *accountStore;
    ACAccountType *accountTypeFB;
    if ((accountStore = [[ACAccountStore alloc] init]) && (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
        
        NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
        NSLog(@"fbAccounts: %@",fbAccounts);
        id account;
        if (fbAccounts && [fbAccounts count] > 0 && (account = [fbAccounts objectAtIndex:0])){
            
            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                //we don't actually need to inspect renewResult or error.
                if (error){
                    
                }
            }];
        }
    }
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{

    switch (state) {
        case FBSessionStateOpen:
            if ([session accessToken] != nil){
                [FBSession setActiveSession:session];
                [[FDAPIClient sharedClient] connectUser:nil email:nil password:nil signup:NO fbid:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] success:^(id result) {
                    [self.window.rootViewController performSegueWithIdentifier:@"ShowFeed" sender:self];
                } failure:^(NSError *error) {
                    NSLog(@"failure establishing user session from app delegate fb method: %@",error.description);
                }];
                
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            [self fbResync];
            break;
        default:
            break;
    }
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"We can't connect"
                                  message:@"Please make sure that you've authorized your phone's Facebook account to log into FOODIA."
                                  delegate:nil
                                  cancelButtonTitle:@"Okay"
                                  otherButtonTitles:nil];
        [alertView show];
        //NSLog(@"Error: %@",error.localizedDescription);
    } 
    
}

-(BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    return [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObjects:@"email", @"user_location", nil] allowLoginUI:allowLoginUI completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         FBSession.activeSession = session;
         FBRequest *request = [[FBRequest alloc] initWithSession:session graphPath:@"me"];
         [request startWithCompletionHandler:
          ^(FBRequestConnection *connection,
            NSDictionary<FBGraphUser> *user,
            NSError *error) {
              if (!error) {
                  [[NSUserDefaults standardUserDefaults] setObject:user.id forKey:kUserDefaultsFacebookId];
                  [[NSUserDefaults standardUserDefaults] setObject:session.accessToken forKey:kUserDefaultsFacebookAccessToken];
                  [[NSUserDefaults standardUserDefaults] setObject:user.name forKey:kUserDefaultsUserName];
                  [Utilities cacheUserProfileImage];
                  [self sessionStateChanged:session state:state error:error];
              } else {
                  //NSLog(@"error from facebook: %@", error.description);
              }
          
          }];
         
     }];
}

-(void)getPublishPermissions {
        NSArray *permissions = [NSArray arrayWithObjects:@"publish_actions", nil];
    [[FBSession activeSession] reauthorizeWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
    }];
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kUserDefaultsFacebookAccessToken];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Okay"]){
        [self openSessionWithAllowLoginUI:YES];
    }
}

- (void)showLoadingOverlay
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Loading"]){
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        UIImageView *imgOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, width, height)];
        [imgOverlay setImage:[UIImage imageNamed:@"overlay4"]];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.hidesWhenStopped = YES;
        [activityIndicator startAnimating];
        activityIndicator.center = CGPointMake(width/2, height/2);
        
        [imgOverlay setTag:23];
        [imgOverlay setAlpha:0];
        [imgOverlay addSubview:activityIndicator];
        [activityIndicator setAlpha:0.0];
        
        [self.window addSubview:imgOverlay];
        
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            imgOverlay.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [activityIndicator setAlpha:1.0];
            } completion:^(BOOL finished) {
                
            }];
        }];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Loading"];
        //always remove loading indicator after 10.0 seconds. 
        [self performSelector:@selector(hideLoadingOverlay) withObject:nil afterDelay:10.0];
    }
}

- (void)hideLoadingOverlay
{
    UIView *imgOverlay = [self.window viewWithTag:23];
    [UIView animateWithDuration:0.3 animations:^{
        imgOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        [imgOverlay removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Loading"];
    }];
}

- (void)feedDialogWithParams:(NSMutableDictionary *)params {
    [self.facebook dialog:@"feed" andParams:params andDelegate:self];
}

- (void)showUserProfile:(NSString *)facebookId
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:facebookId forKey:@"fbid"];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ShowProfile"
     object:self
     userInfo:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if (self.isTakingPhoto) [[NSNotificationCenter defaultCenter] postNotificationName:@"CleanupCameraCapture" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //UIViewController* root = _window.rootViewController;
    //UIViewController * mycontroller = [[(UINavigationController*)root viewControllers] objectAtIndex:0];
    if (self.isTakingPhoto){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"StartCameraCapture" object:nil];
        NSLog(@"user is taking a photo");
    }
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //[MagicalRecord cleanUp];
    [FBSession.activeSession closeAndClearTokenInformation];
}


- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
    return [FBSession.activeSession handleOpenURL:url]; 
}

#pragma mark - Private Methods

- (void)customizeAppearance {
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"newFoodiaHeader.png"] forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"newFoodiaHeader.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [UIColor blackColor], UITextAttributeTextColor, [UIFont fontWithName:kAvenirMedium size:21], UITextAttributeFont, [UIColor clearColor], UITextAttributeTextShadowColor, nil]];
    
    UIImage *emptyBarButton = [UIImage imageNamed:@"emptyBarButton.png"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -2.0f) forBarMetrics:UIBarMetricsDefault];
    } else {
        [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, 0.5f) forBarMetrics:UIBarMetricsDefault];
    }
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                        UITextAttributeFont : [UIFont fontWithName:kAvenirMedium size:15],
                             UITextAttributeTextShadowColor : [UIColor clearColor],
                                   UITextAttributeTextColor : [UIColor blackColor],
         } forState:UIControlStateNormal];
    } else {
        [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                   UITextAttributeTextColor : [UIColor blackColor],
         } forState:UIControlStateNormal];
    }
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0f, 0.0f) forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"textField.png"]forState:UIControlStateNormal];
     
    
    

}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end
