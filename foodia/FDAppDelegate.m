//
//  FDAppDelegate.m
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDLoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "FDPost.h"
#import "FDUser.h"
#import "FDCache.h"
#import "ECSlidingViewController.h"
#import "FDTumblrAPIClient.h"
#import "FDNewPostViewController.h"
#import "Flurry.h"
#import "FDProfileViewController.h"
#import "Utilities.h"

@interface FDAppDelegate ()
@property (strong,nonatomic) UILabel *wallPost;
@property UIButton *tryReconnecting;
@property UILabel *noConnection;
@end

@implementation FDAppDelegate

@synthesize wallPost, noConnection, tryReconnecting;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Yay FOODIA!
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self customizeAppearance];
    
    [self performSetup];
    [[FDAPIClient sharedClient] setFacebookID:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookID"]];
    [[FDAPIClient sharedClient] setFacebookAccessToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookAccessToken"]];
    
    //[MagicalRecord setupCoreDataStackWithStoreNamed:@"FoodiaV2.sqlite"];
    [Flurry startSession:@"W5U7NXYMMQ8RJQR7WI9A"];
    [TestFlight takeOff:(@"13a30f1fa03141084d0983b4e6f3e04f_NjQ4NDkyMDEyLTAyLTI0IDE1OjExOjM4LjE1Mjg3Mg")];
    
    [FDCache clearCache];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    return YES;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage
{
    NSLog(@"just got a remote notification: %@",pushMessage);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [[FDAPIClient sharedClient] setDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
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

-(void)setupNoConnection{
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
    self.noConnection.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:18];
    self.noConnection.text = @"Sorry, but you'll need the internet to use FOODIA.";
    self.noConnection.textColor = [UIColor whiteColor];
    self.noConnection.textAlignment = UITextAlignmentCenter;
    self.noConnection.numberOfLines = 3;
    
    self.tryReconnecting = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tryReconnecting setBackgroundColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.75]];
    self.tryReconnecting.layer.cornerRadius = 3.0f;
    [self.tryReconnecting setFrame:CGRectMake(screen.size.width*0.175,screen.size.height*0.55,screen.size.width*0.65,screen.size.height/16)];
    [self.tryReconnecting addTarget:self action:@selector(openSession) forControlEvents:UIControlEventTouchUpInside];
    self.tryReconnecting.titleLabel.textAlignment = UITextAlignmentCenter;
    [self.tryReconnecting.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20]];
    [self.tryReconnecting setTitle:@"TAP TO RETRY CONNECTION" forState:UIControlStateNormal];
    [self.window addSubview:background];
    [self.window addSubview:noConnection];
    [self.window addSubview:tryReconnecting];
    [self hideLoadingOverlay];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
                       user:(NSDictionary<FBGraphUser>*)user
{
    switch (state) {
        case FBSessionStateOpen:
            if ([session accessToken] != nil)[self.window.rootViewController performSegueWithIdentifier:@"ShowFeed" sender:self];
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed: 
            [FBSession.activeSession closeAndClearTokenInformation];
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
        NSLog(@"Error: %@",error.localizedDescription);
    } 
    
}

-(void)openSession {
    [FBSession openActiveSessionWithReadPermissions:[NSArray arrayWithObjects:@"email", nil] allowLoginUI:YES completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         FBRequest *request = [[FBRequest alloc] initWithSession:session graphPath:@"me"];
         [request startWithCompletionHandler:
          ^(FBRequestConnection *connection,
            NSDictionary<FBGraphUser> *user,
            NSError *error) {
              if (!error) {
                  [[FDAPIClient sharedClient] setFacebookID: user.id];
                  [[FDAPIClient sharedClient] setFacebookAccessToken:session.accessToken];
                  [[NSUserDefaults standardUserDefaults] setObject:user.id forKey:@"FacebookID"];
                  [[NSUserDefaults standardUserDefaults] setObject:session.accessToken forKey:@"FacebookAccessToken"];
                  [[NSUserDefaults standardUserDefaults] setObject:user.name forKey:@"userName"];
                  [Utilities cacheUserProfileImage];
              } 
              [self sessionStateChanged:session state:state error:error user:user];
          }];
     }];
}

-(void)getPublishPermissions {
        NSArray *permissions = [NSArray arrayWithObjects:@"publish_actions", nil];
    [[FBSession activeSession] reauthorizeWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
    }];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Okay"]){
        [self openSession];
    }
}

- (void)showLoadingOverlay
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Loading"]){
        CGFloat halfWidth = [[UIScreen mainScreen] bounds].size.width / 2;
        CGFloat halfHeight = [[UIScreen mainScreen] bounds].size.height / 2;
        UIImageView *imgOverlay = [[UIImageView alloc] initWithFrame:CGRectMake((halfWidth - 60), (halfHeight - 60), 120, 120)];
        [imgOverlay setImage:[UIImage imageNamed:@"loading"]];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.center = CGPointMake(60, 60);
        activityIndicator.hidesWhenStopped = YES;
        [imgOverlay addSubview:activityIndicator];
        [imgOverlay setTag:99999991];
        [imgOverlay setAlpha:0];
        
        [self.window addSubview:imgOverlay];
        [activityIndicator startAnimating];
        
        [UIView animateWithDuration:0.4 animations:^{
            imgOverlay.alpha = 1;
        }];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Loading"];
    }
}

- (void)hideLoadingOverlay
{
    UIView *imgOverlay = [self.window viewWithTag:99999991];
    [UIView animateWithDuration:0.3 animations:^{
        imgOverlay.alpha = 0.0;
        imgOverlay.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
        [imgOverlay removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Loading"];
    }];
}


- (void)showUserProfile:(NSString *)facebookId
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:facebookId forKey:@"fbid"];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ShowProfile"
     object:self
     userInfo:userInfo];
}

- (void)showFacebookWallPost
{
    wallPost = [[UILabel alloc] initWithFrame:CGRectMake(0,self.window.bounds.size.height-22,self.window.bounds.size.width,22)];
    wallPost.text = @"Invites will be sent to your friend's Facebook wall";
    wallPost.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14];
    wallPost.backgroundColor = [UIColor whiteColor];
    wallPost.textColor = [UIColor darkGrayColor];
    wallPost.textAlignment = UITextAlignmentCenter;
    [wallPost setAlpha:0];
    [self.window addSubview:wallPost];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    wallPost.alpha = 1;
    [UIView commitAnimations];
}

- (void)removeFacebookWallPost
{
    [wallPost removeFromSuperview];
}
     
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [UIColor blackColor], UITextAttributeTextColor, [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:25], UITextAttributeFont, nil]];
    
    UIImage *emptyBarButton = [UIImage imageNamed:@"emptyBarButton.png"];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -2.0f) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeFont : [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15],
                                                UITextAttributeTextShadowColor : [UIColor clearColor],
                                                    UITextAttributeTextColor : [UIColor blackColor],
    } forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0f, 0.0f) forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [[UISearchBar appearance] setSearchFieldBackgroundImage:[UIImage imageNamed:@"textField.png"]forState:UIControlStateNormal];
     
    /*TODO:: iOS 6 Future Code
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
       
    } else {
        
    }*/

}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end
