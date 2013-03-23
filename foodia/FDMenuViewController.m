//
//  FDMenuViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDMenuViewController.h"
#import "ECSlidingViewController.h"
#import <MessageUI/MessageUI.h>
#import "FDCache.h"
#import "Facebook.h"
#import "FDAPIClient.h"
#import "FDProfileViewController.h"
#import "FDProfileNavigationController.h"
#import "ECSlidingViewController.h"
#import "FDNotificationCell.h"
#import "FDPostCell.h"
#import "FDPost.h"
#import "FDPostViewController.h"
#import "FDProfileViewController.h"
#import "FDProfileNavigationController.h"
#import "FDModalNoAnimationSegue.h"
#import "FDFeedNavigationViewController.h"
#import "Utilities.h"
#import "Flurry.h"

@interface FDMenuViewController () <MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) NSArray *activityItems;
@property (weak, nonatomic) UIView *titleView;
@property (weak, nonatomic) UILabel *activityLabel;
@end

@implementation FDMenuViewController
@synthesize activityItems;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"ViewingMenu" timed:YES];
    [self refresh];
    [self.slidingViewController setAnchorRightRevealAmount:264.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    self.tableView.separatorColor = [UIColor colorWithWhite:.1 alpha:.1];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedTypeMenuBackground4@2x.png"]];
    //self.tableView.backgroundView.transform = CGAffineTransformMakeRotation(M_PI);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)return 5;
    else {
        return self.notifications.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"MenuCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:[UIColor darkGrayColor]];
        cell.selectedBackgroundView = cellbg;
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"HOME";
                break;
                case 1:
                    cell.textLabel.text = @"MY POSTS";
                    break;
                case 2:
                    cell.textLabel.text = @"FRIENDS & INVITES";
                break;
                case 3:
                    cell.textLabel.text = @"FEEDBACK";
                break;
                case 4:
                    cell.textLabel.text = @"LOG OUT";
                    break;
                default:
                break;
        }
        return cell;
    } else {
        static NSString *CellIdentifier = @"NotificationCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:[UIColor darkGrayColor]];
        cell.selectedBackgroundView = cellbg;
        FDNotification *notification = [self.notifications objectAtIndex:indexPath.row];
        UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5,7,36,36)];
        [profileImageView setImageWithURL:[Utilities profileImageURLForFacebookID:notification.fromUserFbid]];
        profileImageView.clipsToBounds = YES;
        profileImageView.layer.cornerRadius = 5.0;
        profileImageView.layer.shouldRasterize = YES;
        profileImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,4,180,40)];
        [messageLabel setTextColor:[UIColor darkGrayColor]];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            [messageLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14]];
        } else {
            [messageLabel setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16]];
        }
        messageLabel.numberOfLines = 2;
        messageLabel.backgroundColor = [UIColor clearColor];
        [messageLabel setText:notification.message];
        messageLabel.highlightedTextColor = [UIColor whiteColor];
        
        // show the time stamp
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(220,14,30,21)];
        [timeLabel setTextColor:[UIColor lightGrayColor]];
        timeLabel.textAlignment = NSTextAlignmentRight;
        [timeLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14]];
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.highlightedTextColor = [UIColor whiteColor];
        if([notification.postedAt timeIntervalSinceNow] > 0) {
            timeLabel.text = @"0s";
        } else {
            timeLabel.text = [Utilities timeIntervalSinceStartDate:notification.postedAt];
        }
        CGRect imagePicFrame = profileImageView.frame;
        [profileButton setFrame:imagePicFrame];
        [profileButton setBackgroundColor:[UIColor clearColor]];
        [profileButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        profileButton.titleLabel.text = notification.fromUserFbid;
        profileButton.titleLabel.hidden = YES;
        [cell addSubview:profileImageView];
        [cell addSubview:messageLabel];
        [cell addSubview:timeLabel];
        [cell addSubview:profileButton];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 54.0f;
    else return 50.0f;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 1) {
        FDNotification *notification = [self.notifications objectAtIndex:indexPath.row];
        if (notification.targetPostId != nil) {
            [self showPost:[NSString stringWithFormat:@"%@",notification.targetPostId]];
        } else if (notification.targetUserId != nil) {
            [self showProfile:[NSString stringWithFormat:@"%@", notification.targetUserId]];
        }
    } else {
    switch (indexPath.row) {
        case 0:
            [self showTopViewControllerWithIdentifier:@"FeedNavigation"];
            break;
        case 1:
            [self showTopViewControllerWithIdentifier:@"ProfileNavigation"];
            break;
        case 2:
            [self showTopViewControllerWithIdentifier:@"SocialNavigation"];
            break;
        case 3:
            [self leaveFeedback:nil];
            break;
        case 4:
        {
            [FDCache clearCache];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JustLaunched"];
            [FBSession.activeSession closeAndClearTokenInformation];
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [NSUserDefaults resetStandardUserDefaults];
            [NSUserDefaults standardUserDefaults];
            NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
            [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
            [self.slidingViewController dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        default:
            break;
        }
    }
}

- (void)showTopViewControllerWithIdentifier:(NSString *)identifier {
    UIViewController *newTopViewController = [[UIViewController alloc] init];
    //tests whether the device has a 4-inch display for the above view controllers
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        newTopViewController = [storyboard5 instantiateViewControllerWithIdentifier:identifier];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        newTopViewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    }
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = newTopViewController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self.slidingViewController resetTopView];
    }];
}

- (void)showProfile:(id)sender{
    FDProfileViewController *newTopViewController = [[FDProfileViewController alloc] init];
    //tests whether the device has a 4-inch display for the above view controllers
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        newTopViewController = [storyboard5 instantiateViewControllerWithIdentifier:@"ProfileView"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        newTopViewController = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    }
    if ([sender isMemberOfClass:[UIButton class]]) {
        UIButton *button = (UIButton*)sender;
        [newTopViewController initWithUserId:button.titleLabel.text];
    } else {
        NSString *userId = (NSString*)sender;
        [newTopViewController initWithUserId:userId];
    }
    [(UINavigationController*)self.slidingViewController.topViewController pushViewController:newTopViewController animated:YES];
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        [self.slidingViewController resetTopView];
    }];
}

- (void)showPost:(id)sender{
    FDPostViewController *vc = [[FDPostViewController alloc] init];
    //tests whether the device has a 4-inch display for the above view controllers
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        vc = [storyboard5 instantiateViewControllerWithIdentifier:@"PostView"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        vc = [storyboard instantiateViewControllerWithIdentifier:@"PostView"];
    }
    NSString *postId = (NSString *) sender;
    [vc setPostIdentifier:postId];
    [(UINavigationController*)self.slidingViewController.topViewController pushViewController:vc animated:YES];
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        [self.slidingViewController resetTopView];
    }];
}
#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)leaveFeedback:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        [controller setSubject:@"FOODIA Feedback"];
        [controller setToRecipients:[NSArray arrayWithObjects:@"feedback@foodia.org", nil]];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks" message:@"Please send feedback to feedback@foodia.org" delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
        [alert show];
    }
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {}
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refresh
{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivitySuccess:^(NSMutableArray *notifications) {
        self.notifications = notifications;
        self.feedRequestOperation = nil;
        NSLog(@"refreshing activities list");
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        NSLog(@"Loading Activities Failed");
    }];
}

@end
