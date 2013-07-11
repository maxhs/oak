//
//  FDMenuViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDMenuViewController.h"
#import "Constants.h"
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
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"

@interface FDMenuViewController () {
    BOOL canLoadAdditionalNotifications;
}
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
    [self.slidingViewController setAnchorRightRevealAmount:272.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    self.tableView.separatorColor = [UIColor colorWithWhite:.1 alpha:.1];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedTypeMenuBackground4@2x.png"]];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
    canLoadAdditionalNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shrink) name:@"ShrinkMenuView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grow) name:@"GrowMenuView" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self shrink];
}

- (void) grow {
    if (self.tableView.alpha != 1.0){
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            //self.slidingViewController.underLeftViewController.view.transform = CGAffineTransformIdentity;
            //[self.slidingViewController.topViewController.view setAlpha:0.25];
            [self.tableView setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void) shrink {
    if (self.tableView.alpha != 0.0) {
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            //[self.slidingViewController.topViewController.view setAlpha:1.0];
            //self.slidingViewController.underLeftViewController.view.transform = CGAffineTransformMakeScale(0.90, 0.90);
            [self.tableView setAlpha:0.0];
        } completion:^(BOOL finished) {
        
        }];
    }
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
        [cellbg setBackgroundColor:kColorLightBlack];
        cell.selectedBackgroundView = cellbg;
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"HOME";
                break;
                case 1:
                    cell.textLabel.text = @"MY PROFILE";
                    break;
                case 2:
                    cell.textLabel.text = @"DIGEST";
                    break;
                case 3:
                    cell.textLabel.text = @"FRIENDS";
                    break;
                case 4:
                    cell.textLabel.text = @"SETTINGS";
                default:
                break;
        }
        
        return cell;
    } else {
        static NSString *CellIdentifier = @"NotificationCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:kColorLightBlack];
        cell.selectedBackgroundView = cellbg;
        FDNotification *notification = [self.notifications objectAtIndex:indexPath.row];
        UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [profileButton setFrame:CGRectMake(5,4,40,40)];
        
        //set image
        if (notification.fromUserFbid.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
            [profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:notification.fromUserFbid] forState:UIControlStateNormal];
        } else {
            //set from Amazon. risky...
            [profileButton setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",notification.fromUserId]] forState:UIControlStateNormal];
        }

        profileButton.imageView.layer.cornerRadius = 20.0;
        [profileButton.imageView setBackgroundColor:[UIColor clearColor]];
        [profileButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
        
        profileButton.imageView.layer.shouldRasterize = YES;
        profileButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,4,180,40)];
        [messageLabel setTextColor:[UIColor darkGrayColor]];
        [messageLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
        messageLabel.numberOfLines = 2;
        messageLabel.backgroundColor = [UIColor clearColor];
        [messageLabel setText:notification.message];
        messageLabel.highlightedTextColor = [UIColor whiteColor];
        
        // show the time stamp
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(222,14,36,21)];
        [timeLabel setTextColor:[UIColor lightGrayColor]];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.highlightedTextColor = [UIColor whiteColor];
        [timeLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:13]];
        
        if([notification.postedAt timeIntervalSinceNow] > 0) {
            timeLabel.text = @"0s";
        } else {
            timeLabel.text = [Utilities timeIntervalSinceStartDate:notification.postedAt];
        }
        [profileButton setBackgroundColor:[UIColor clearColor]];
        [profileButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        profileButton.titleLabel.text = notification.fromUserId;
        profileButton.titleLabel.hidden = YES;
        [cell addSubview:profileButton];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 20;
    else return 0;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.feedRequestOperation = nil;
    if (indexPath.section == 1) {
        FDNotification *notification = [self.notifications objectAtIndex:indexPath.row];
        if (notification.targetPostId != nil) {
            NSDictionary *userInfo = @{@"identifier":[NSString stringWithFormat:@"%@", notification.targetPostId]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RowToReloadFromMenu" object:nil userInfo:userInfo];
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
            [self showTopViewControllerWithIdentifier:@"FoodNavigation"];
            break;
        case 3:
            [self showTopViewControllerWithIdentifier:@"SocialNavigation"];
            break;
        case 4:
            [self showTopViewControllerWithIdentifier:@"SettingsNavigation"];
            break;
        default:
            break;
        }
    }
}

- (void)showTopViewControllerWithIdentifier:(NSString *)identifier {
    UIViewController *newTopViewController;
    //tests whether the device has a 4-inch display for the above view controllers
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        newTopViewController = [storyboard5 instantiateViewControllerWithIdentifier:identifier];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        newTopViewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    }
    if ([identifier isEqualToString:@"ProfileNavigation"]){
        [(FDProfileNavigationController*)newTopViewController setUserId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    }
    /*if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        NSLog(@"self.slidingvc: %@", self.slidingViewController.topViewController);
            [self presentViewController:newTopViewController animated:YES completion:nil];
            [self.slidingViewController resetTopView];
        }];
    } else {*/
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    //}
}

- (void)showProfile:(id)sender{
    FDProfileViewController *newTopViewController;
    
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
    FDPostViewController *vc;
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

- (void)refresh
{
    [self grow];
    if (self.notifications.count && self.notifications.count < 200) {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivitySinceNotification:[self.notifications objectAtIndex:0] success:^(NSArray *newNotifications) {
            NSArray *tempArray = [newNotifications arrayByAddingObjectsFromArray:[self.notifications copy]];
            self.notifications = [tempArray mutableCopy];
            self.feedRequestOperation = nil;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
        }];
    } else {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivitySuccess:^(NSMutableArray *notifications) {
            self.notifications = notifications;
            self.feedRequestOperation = nil;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
        }];
    }
}

- (void)loadMoreNotifications {
    self.feedRequestOperation = (AFJSONRequestOperation*)[[FDAPIClient sharedClient] getActivityBeforeNotification:self.notifications.lastObject success:^(NSArray *result) {
        if (result.count == 0){
            canLoadAdditionalNotifications = NO;
        } else {
            [self.notifications addObjectsFromArray:result];
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
            canLoadAdditionalNotifications = YES;
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
    }];
    canLoadAdditionalNotifications = NO;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - [(UITableView*)scrollView rowHeight]*20) {
        [self didShowLastRow];
    }
    
}

- (void)didShowLastRow {
    if (self.notifications.count && canLoadAdditionalNotifications) [self loadMoreNotifications];
}

@end
