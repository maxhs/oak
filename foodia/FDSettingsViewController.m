//
//  FDSettingsViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDSettingsViewController.h"
#import "FDAppDelegate.h"
#import "FDSlidingViewController.h"
#import "FDMenuViewController.h"
#import "Flurry.h"
#import "FDCache.h"
#import "FDUser.h"
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>

@interface FDSettingsViewController () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) UISwitch *smileSwitch;
@property (strong, nonatomic) UISwitch *geofenceSwitch;
@property (strong, nonatomic) UISwitch *followSwitch;
@property (strong, nonatomic) UISwitch *featureSwitch;
@property (strong, nonatomic) UISwitch *commentSwitch;
@property (strong, nonatomic) UISwitch *emailSwitch;
@property (strong, nonatomic) UISwitch *featuredFeedSwitch;
@property (strong, nonatomic) FDUser *user;
- (IBAction)revealMenu:(UIBarButtonItem *)sender;
- (IBAction)save;
@end

@implementation FDSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [[FDAPIClient sharedClient] getUserSettingsSuccess:^(FDUser *resultUser) {
        self.user = resultUser;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        
    }];
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [Flurry logEvent:@"Viewing Settings" timed:YES];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,180,44);
    navTitle.text = @"Settings";
    navTitle.font = [UIFont fontWithName:kHelveticaNeueThin size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    UIImageView *backgroundView = [[UIImageView alloc] init];
    [backgroundView setBackgroundColor:[UIColor whiteColor]];
    self.tableView.backgroundView = backgroundView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 2;
    else if (section == 1) return 5;
    else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
    UIView *cellbg = [[UIView alloc] init];
    [cellbg setBackgroundColor:kColorLightBlack];
    cellbg.layer.cornerRadius = 5.0f;
    cellbg.clipsToBounds = YES;
    cell.selectedBackgroundView = cellbg;
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                UIView *cellbg = [[UIView alloc] init];
                [cellbg setBackgroundColor:kColorLightBlack];
                cell.selectedBackgroundView = cellbg;
                cell.textLabel.text = @"Send feedback";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
            }
                break;
            case 1:
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                cell.textLabel.text = @"Show FEATURED first?";
                self.featuredFeedSwitch = [[UISwitch alloc] init];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kShouldShowFeaturedFirst]){
                    [self.featuredFeedSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kShouldShowFeaturedFirst]];
                } else {
                    [self.featuredFeedSwitch setOn:YES];
                }
                cell.accessoryView = self.featuredFeedSwitch;
                [cell.textLabel setTextAlignment:NSTextAlignmentLeft];
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Smile notifications";
                self.smileSwitch = [[UISwitch alloc] init];
                if (self.user.pushSmile) [self.smileSwitch setOn:YES animated:YES];
                else [self.smileSwitch setOn:NO animated:YES];
                cell.accessoryView = self.smileSwitch;
                break;
            case 1:
                cell.textLabel.text = @"Follow notifications";
                self.followSwitch = [[UISwitch alloc] init];
                if (self.user.pushFollow) [self.followSwitch setOn:YES animated:YES];
                else [self.followSwitch setOn:NO animated:YES];
                cell.accessoryView = self.followSwitch;
                break;
            case 2:
                cell.textLabel.text = @"Comment notifications";
                self.commentSwitch = [[UISwitch alloc] init];
                if (self.user.pushComment) [self.commentSwitch setOn:YES animated:YES];
                else [self.commentSwitch setOn:NO animated:YES];
                cell.accessoryView = self.commentSwitch;
                break;
            case 3:
                cell.textLabel.text = @"Post feature notifications";
                self.featureSwitch = [[UISwitch alloc] init];
                cell.accessoryView = self.featureSwitch;
                if (self.user.pushFeature) [self.featureSwitch setOn:YES animated:YES];
                else [self.featureSwitch setOn:NO animated:YES];
                
                break;
            /*case 4:
                cell.textLabel.text = @"Geofence Notifications";
                self.geofenceSwitch = [[UISwitch alloc] init];
                if (self.user.pushGeofence) [self.geofenceSwitch setOn:YES animated:YES];
                else [self.geofenceSwitch setOn:NO animated:YES];
                cell.accessoryView = self.geofenceSwitch;
                break;*/
            case 4:
                cell.textLabel.text = @"Email notifications";
                self.emailSwitch = [[UISwitch alloc] init];
                if (self.user.emailNotifications) [self.emailSwitch setOn:YES animated:YES];
                else [self.emailSwitch setOn:NO animated:YES];
                cell.accessoryView = self.emailSwitch;
                
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Log out";
            default:
                break;
        }
        
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,320,44)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    titleLabel.textColor = [UIColor lightGrayColor];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:18]];
    
    if (section == 0){
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,0)];
        titleLabel.text = @"";
    } else if (section == 1) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,44)];
        titleLabel.text = @"Push Notifications";
    } else if (section == 2) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,0)];
        titleLabel.text = [NSString stringWithFormat:@"v.%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
    [headerView addSubview:titleLabel];
    return headerView;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"First Section";
            break;
        case 1:
            return @"Push Notifications";
            break;
        case 2:
            return [NSString stringWithFormat:@"You're using v.%@. Thanks!",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        default:
            break;
    }
    return @"FOODIA";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 0;
    else return 34;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (IBAction)save {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    
    if (self.featuredFeedSwitch.isOn) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShouldShowFeaturedFirst];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShouldShowFeaturedFirst];
    }
    
    self.user.pushSmile = self.smileSwitch.isOn;
    self.user.pushGeofence = self.geofenceSwitch.isOn;
    self.user.pushComment = self.commentSwitch.isOn;
    self.user.pushFeature = self.featureSwitch.isOn;
    self.user.pushFollow = self.followSwitch.isOn;
    self.user.emailNotifications = self.emailSwitch.isOn;
    [[FDAPIClient sharedClient] updateUserSettings:self.user success:^(id result) {
        [self performSelector:@selector(transitionView) withObject:nil afterDelay:0.5f];
    } failure:^(NSError *error) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But something went wrong while trying to update your settings. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to update user settings: %@",error.description);
    }];
}

- (void)transitionView {
    //[(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    UIViewController *newTopViewController = [[UIViewController alloc] init];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        newTopViewController = [storyboard5 instantiateViewControllerWithIdentifier:@"FeedNavigation"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        newTopViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedNavigation"];
    }
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = newTopViewController;
    self.slidingViewController.topViewController.view.frame = frame;
    //[self.slidingViewController resetTopView];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController refresh];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) [self leaveFeedback];
    } else if (indexPath.section == 2) {
        NSLog(@"Logging out.");
        [FDCache clearCache];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate fbDidLogout];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [NSUserDefaults resetStandardUserDefaults];
        [NSUserDefaults standardUserDefaults];
        NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)leaveFeedback {
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


@end
