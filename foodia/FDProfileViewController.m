//
//  FDProfileViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/16/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDProfileViewController.h"
#import "FDProfileNavigationController.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"
#import "FDPost.h"
#import "Utilities.h"
#import "FDPostCell.h"
#import "FDPostTableViewController.h"
#import "FDPostViewController.h"
#import "FDPeopleTableViewController.h"
#import "Constants.h"
#import "FDUserCell.h"
#import "FDProfileMapViewController.h"
#import "Facebook.h"
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import "FDRecommendViewController.h"
#import "FDCustomSheet.h"
#import "FDPlaceViewController.h"
#import "FDMenuViewController.h"
#import "UIButton+WebCache.h"
#import <CoreLocation/CoreLocation.h>

#define kLargePostList CGRectMake(0,114,320,390)
#define kSmallPostList CGRectMake(0,114,320,390)
NSString* const searchBarPlaceholder = @"Search for food and drink";
NSString* const locationBarPlaceholder = @"Search the places you've been";

@interface FDProfileViewController() <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>
@property BOOL myProfile;
@property BOOL justLiked;
@property (nonatomic) BOOL canLoadMore;
@property CGRect postListRect;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *activateSearchButton;
@property (nonatomic, weak) IBOutlet UIView *profileDetailsContainerView;
@property int *postListHeight;
@property BOOL isSearching;
@property (nonatomic, strong) AFHTTPRequestOperation *objectSearchRequestOperation;
@property (nonatomic, strong) AFHTTPRequestOperation *postSearchRequestOperation;
@property (weak, nonatomic) IBOutlet UIView *postsButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *followersButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *followingButtonBackground;
@property (strong, nonatomic) UISearchDisplayController *locationSearchDisplayController;
@property (strong, nonatomic) UIButton *editButton;
@property BOOL noSearchResults;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSArray *userVenues;
@property (strong, nonatomic) NSMutableArray *filteredUserVenues;
@property (strong, nonatomic) NSString *selectedVenue;

@end

@implementation FDProfileViewController
@synthesize profileButton;
@synthesize postList;
@synthesize myProfile = _myProfile;
@synthesize justLiked = _justLiked;
@synthesize user;
@synthesize userId;
@synthesize profileContainerView;
@synthesize userNameLabel;
@synthesize inactiveLabel;
@synthesize postCountLabel, followingCountLabel, followerCountLabel;
@synthesize feedRequestOperation;
@synthesize detailsRequestOperation;
@synthesize followers;
@synthesize following;
@synthesize currentTab;
@synthesize currButton;
@synthesize canLoadMore;
@synthesize postListRect = _postListRect;
@synthesize objectSearchRequestOperation;
@synthesize postSearchRequestOperation;
@synthesize editButton = _editButton;
@synthesize isSearching = _isSearching;
@synthesize noSearchResults = _noSearchResults;
@synthesize geocoder = _geocoder;
@synthesize location = _location;
@synthesize locationSearchDisplayController = _locationSearchDisplayController;
@synthesize userVenues = _userVenues;
@synthesize filteredUserVenues = _filteredUserVenues;
@synthesize selectedVenue = _selectedVenue;

- (void)initWithUserId:(NSString *)uid {
    self.userId = uid;
    self.canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        if ([[result objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
            [profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:[result objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
        } else if ([result objectForKey:@"avatar_url"] != [NSNull null]) {
            [profileButton setImageWithURL:[NSURL URLWithString:[result objectForKey:@"avatar_url"]] forState:UIControlStateNormal];
        }
        currButton = @"follow";
        self.followers = [NSArray array];
        self.following = [NSArray array];
        self.filteredUserVenues = [NSMutableArray array];
        if ([result objectForKey:@"id"])[self showPosts:[result objectForKey:@"id"]];
        [self.postList setHidden:false];
        [self.inactiveLabel setHidden:true];
        if ([result objectForKey:@"name"] != [NSNull null]) self.userNameLabel.text = [result objectForKey:@"name"];
        [self.userNameLabel setTextColor:[UIColor blackColor]];
        if([result objectForKey:@"active"]) {
            self.postCountLabel.text = [NSString stringWithFormat:@"%@ Posts",[[result objectForKey:@"post_count"] stringValue]];
            self.followingCountLabel.text = [NSString stringWithFormat:@"Following %@",[[result objectForKey:@"following_count"] stringValue]];
            self.followerCountLabel.text = [NSString stringWithFormat:@"%@ Followers",[[result objectForKey:@"follower_count"] stringValue]];
            if([result objectForKey:@"is_following"]) {
                [self.socialButton setTitle:@"FOLLOWING" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor lightGrayColor]];
                [self.socialButton.layer setBorderColor:[UIColor clearColor].CGColor];
                currButton = @"following";
            } else {
                [self.socialButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor redColor]];
                [self.socialButton.layer setBorderColor:[UIColor redColor].CGColor];
                currButton = @"follow";
            }
            self.followers = [result objectForKey:@"followers_arr"];
            self.following = [result objectForKey:@"following_arr"];
            [self.postList reloadData];
        
        } else {
            [self.socialButton setTitle:@"INVITE" forState:UIControlStateNormal];
            [self.postList setHidden:true];
            [self.inactiveLabel setHidden:false];
            currButton = @"invite";
        }
    } failure:^(NSError *error) {

    }];
    if (self.myProfile){
        [self.socialButton setHidden:YES];
        self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.editButton setFrame:CGRectMake(80,0,160,34)];
        [self.editButton addTarget:self action:@selector(editProfile) forControlEvents:UIControlEventTouchUpInside];
        [self.editButton setEnabled:YES];
        [self.editButton setTitle:@"EDIT MY PROFILE" forState:UIControlStateNormal];

        self.editButton.layer.borderWidth = .5f;
        self.editButton.layer.cornerRadius = 17.0f;
        self.editButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [self.editButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.editButton.showsTouchWhenHighlighted = YES;
        [self.view addSubview:self.editButton];
        [self.view bringSubviewToFront:self.editButton];
    }
    self.user = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [self.editButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
    } else {
        [self.editButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
    }
}

-(IBAction)followButtonTapped {
    if([currButton isEqualToString:@"follow"]) {
        NSLog(@"Follow Tapped...");
        [[FDAPIClient sharedClient] followUser:self.userId];
        //temporarily change follow number
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter+=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d Followers",followerCounter];
        self.currButton = @"following";
        [self.socialButton setTitle:@"FOLLOWING" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.socialButton.layer.borderColor = [UIColor clearColor].CGColor;
    } else if([currButton isEqualToString:@"following"]) {
        NSLog(@"unfollowing Tapped...");
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter-=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d Followers",followerCounter];
        
        (void)[[FDAPIClient sharedClient] unfollowUser:self.userId];
        
        self.currButton = @"follow";
        [self.socialButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    } else if([currButton isEqualToString:@"invite"]) {
        NSLog(@"Invite Tapped...");
        [self inviteUser:self.userId];
        [self.socialButton setTitle:@"INVITED" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [Flurry logPageView];
    self.geocoder = [[CLGeocoder alloc] init];
    [self.postList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.currentTab = 0;
    [self.navigationController setNavigationBarHidden:NO];
    
    self.profileButton.imageView.layer.cornerRadius = 38.0;
    [self.profileButton.imageView setBackgroundColor:[UIColor clearColor]];
    [self.profileButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.profileButton.imageView.layer.shouldRasterize = YES;
    self.profileButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.filteredPosts = [NSMutableArray array];
    self.followers = [NSArray array];
    self.following = [NSArray array];
    [self.postList setDataSource:self];
    [self.postList setDelegate:self];
    self.makingButton.layer.cornerRadius = 17.0;
    self.eatingButton.layer.cornerRadius = 17.0;
    self.drinkingButton.layer.cornerRadius = 17.0;
    self.shoppingButton.layer.cornerRadius = 17.0;
    self.postsButtonBackground.layer.cornerRadius = 20.0;
    self.followersButtonBackground.layer.cornerRadius = 20.0;
    self.followingButtonBackground.layer.cornerRadius = 20.0;
    [self.searchBar setDelegate:self];
    [self.locationSearchBar setDelegate:self];
    self.searchBar.transform = CGAffineTransformMakeTranslation(320, 0);
    self.locationSearchBar.transform = CGAffineTransformMakeTranslation(320, 0);
    self.searchBar.placeholder = searchBarPlaceholder;
    self.locationSearchBar.placeholder = locationBarPlaceholder;
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.locationSearchDisplayController = [self.searchDisplayController initWithSearchBar:self.locationSearchBar contentsController:self];
    for (UIView *view in self.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    for (UIView *view in self.locationSearchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
                searchField.font = [UIFont fontWithName:kAvenirMedium size:15];
            } else {
                searchField.font = [UIFont fontWithName:kFuturaMedium size:15];
            }
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.locationSearchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
                searchField.font = [UIFont fontWithName:kAvenirMedium size:15];    
            } else {
                searchField.font = [UIFont fontWithName:kFuturaMedium size:15];
            }
            
        }
    }
    
    //self.searchDisplayController.searchBar.showsScopeBar = YES;
    //self.searchDisplayController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"ALL",@"Eat",@"Drink",@"Make",@"Shop",nil];
    //self.searchDisplayController.searchBar.scopeBarBackgroundImage = [UIImage imageNamed:@"newFoodiaHeader.png"];
    self.socialButton.layer.borderWidth = 1.0f;
    self.socialButton.layer.cornerRadius = 16.0f;
    self.socialButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    [self.followingButtonBackground setBackgroundColor:kColorLightBlack];
    [self.followersButtonBackground setBackgroundColor:kColorLightBlack];
    [self.postsButtonBackground setBackgroundColor:kColorLightBlack];
    [self.postCountLabel setTextColor:[UIColor whiteColor]];
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    if (!self.userId){
        self.myProfile = YES;
        [self initWithUserId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    }
    
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.userNameLabel setFont:[UIFont fontWithName:kFuturaMedium size:20]];
        [self.eatingButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.drinkingButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.makingButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.shoppingButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.postCountLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.followerCountLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.followingCountLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.socialButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
    }
}

- (void)editProfile {
    [self performSegueWithIdentifier:@"EditProfile" sender:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [super viewDidAppear:animated];
    
    self.noSearchResults = NO;
    self.slidingViewController.panGesture.enabled = NO;

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(revealMenu:)];
    if (self.navigationController.navigationBar.backItem == nil) {
        self.navigationItem.leftBarButtonItem = menuButton;
    }
    if ([UIScreen mainScreen].bounds.size.height == 568){
        [self.postList setFrame:kLargePostList];
    } else {
        [self.postList setFrame:kSmallPostList];
    }
    self.postListRect = self.postList.frame;
}

- (void)followCreated:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:YES] forKey:@"is_followed_by_user?"];
    }
}

- (void)followDestroyed:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:NO] forKey:@"is_followed_by_user?"];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
    //else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView && section == 0){
        return self.filteredUserVenues.count;
    } else if (self.filteredPosts.count > 0 && section == 0 && currentTab == 0) {

        return self.filteredPosts.count;
    } else if (self.noSearchResults  && tableView != self.locationSearchDisplayController.searchResultsTableView) {

        return 1;
    } else if(section == 0 && currentTab == 0 && tableView != self.locationSearchDisplayController.searchResultsTableView) {

        return self.posts.count;
    } else if(section == 1 && currentTab == 1 && tableView != self.locationSearchDisplayController.searchResultsTableView) {

        return self.following.count;
    } else if(section == 2 && currentTab == 2 && tableView != self.locationSearchDisplayController.searchResultsTableView) {
        return self.followers.count;
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && tableView != self.locationSearchDisplayController.searchResultsTableView) return 155;
    else return 44;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [self.postList setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [UIView animateWithDuration:.25 animations:^{
            [self.socialButton setAlpha:1.0];
        }];
    }
}

-(void)loadPosts:(NSString *)uid{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:uid success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        if (self.posts.count == 0) {
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [UIView animateWithDuration:.25 animations:^{
                [self.socialButton setAlpha:1.0];
                [self.postsButtonBackground setAlpha:1.0];
            }];
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView) {
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationCell"];
        NSString *location = (NSString*)[self.filteredUserVenues objectAtIndex:indexPath.row];
        [cell.textLabel setText:location];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            [cell.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:15.0]];
        } else {
            [cell.textLabel setFont:[UIFont fontWithName:kFuturaMedium size:15.0]];
        }

        
        return cell;
    } else if (indexPath.section == 0 && !self.noSearchResults) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        FDPost *post;
        if (self.filteredPosts.count > 0) {
            post = [self.filteredPosts objectAtIndex:indexPath.row];
        } else {
            post = [self.posts objectAtIndex:indexPath.row];
        }
        [cell configureForPost:post];
        cell = [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        cell.detailPhotoButton.tag = [post.identifier integerValue];
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        cell.recButton.tag = indexPath.row;

        cell.commentButton.tag = [post.identifier integerValue];
        [cell.commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        //capture touch event to show user place map
        if (post.locationName.length){
            [cell.locationButton setHidden:NO];
            [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
            cell.locationButton.tag = indexPath.row;
        }
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        
        return cell;
    } else if (indexPath.section == 1) {
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil] lastObject];
        }
        FDUser *thisUser = [self.following objectAtIndex:indexPath.row];
        [cell configureForUser:thisUser];
        [cell.nameLabel setText:thisUser.name];
        
        /*if ([[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"]){
            [cell setFacebookId:[[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        } else {
            [cell setUserId:[[self.following objectAtIndex:indexPath.row] objectForKey:@"id"]];
        }*/
        
        [cell.actionButton setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];

        peopleButton.tag = [thisUser.userId integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.profileButton.frame];
        return cell;
        
    } else if (indexPath.section == 2){
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil] lastObject];
        }
        FDUser *thisUser = [self.followers objectAtIndex:indexPath.row];
        cell.nameLabel.text = thisUser.name;
        [cell configureForUser:thisUser];
        /*if ([[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"]){
            [cell setFacebookId:[[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        } else {
            [cell setUserId:[[self.followers objectAtIndex:indexPath.row] objectForKey:@"id"]];
        }*/
        [cell.actionButton setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        
        peopleButton.tag = [thisUser.userId integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.profileButton.frame];
        return cell;
    } else {
        NSLog(@"returning an empty cell");
        [self.locationSearchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.postList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        [emptyCell.textLabel setText:@"No Results"];
        [emptyCell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [emptyCell.textLabel setTextColor:[UIColor lightGrayColor]];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            [emptyCell.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:20.0]];
        } else {
            [emptyCell.textLabel setFont:[UIFont fontWithName:kFuturaMedium size:20.0]];
        }
        
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostCell class]]){
        FDPostCell *thisCell = (FDPostCell*)cell;
        [thisCell.scrollView setContentOffset:CGPointMake(0,0) animated:NO];
        [UIView animateWithDuration:.2 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
        }];
    }
}

- (void)didSelectRow:(id)sender {
    //UIButton *button = (UIButton*)sender;
    [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:sender];
}

-(void)showPlace:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    if (self.filteredPosts.count > 0) {
        [self performSegueWithIdentifier:@"ShowPlace" sender:[self.filteredPosts objectAtIndex:button.tag]];
    } else {
        [self performSegueWithIdentifier:@"ShowPlace" sender:[self.posts objectAtIndex:button.tag]];
    }
}

- (void)recommend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    FDCustomSheet *actionSheet;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA", @"Recommend via Facebook",@"Send a Text", @"Send an Email", nil];
    } else {
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA", @"Send a Text", @"Send an Email", nil];
    }
     
    [actionSheet setFoodiaObject:post.foodiaObject];
    [actionSheet setPost:post];
    [actionSheet showInView:self.view];
}

- (void) actionSheet:(FDCustomSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIStoryboard *storyboard;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                               bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                               bundle:nil];
    }
    FDRecommendViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RecommendView"];
    [vc setPost:actionSheet.post];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Recommend on FOODIA"]) {
        //Recommending via FOODIA only
        [vc setPostingToFacebook:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Recommend via Facebook"]) {
        
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound) {
            // No permissions found in session, ask for it
            [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                if (!error) {
                    if ([FBSession.activeSession.permissions
                         indexOfObject:@"publish_actions"] != NSNotFound) {
                        // If permissions granted, go to the rec controller
                        [self.navigationController pushViewController:vc animated:YES];
                        
                    } else {
                        [self dismissViewControllerAnimated:YES completion:nil];
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we'll need your permission in order to post recommendations to Facebook." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                    }
                }
            }];
        } else if ([FBSession.activeSession.permissions
                    indexOfObject:@"publish_actions"] != NSNotFound) {
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send a Text"]) {
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",actionSheet.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self presentViewController:viewController animated:YES completion:nil];
        }
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send an Email"]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", actionSheet.foodiaObject, actionSheet.post.identifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:actionSheet.foodiaObject];
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

#pragma mark - Display likers

- (FDPostCell *)showLikers:(FDPostCell *)cell forPost:(FDPost *)post{
    NSDictionary *viewers = post.viewers;
    NSDictionary *likers = post.likers;
    [cell.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.likersScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *viewer in viewers) {
        if ([viewer objectForKey:@"id"] != [NSNull null]) {
            UIImageView *face = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light_smile"]];

            UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [viewerButton setFrame:CGRectMake(((space+imageSize)*index),0,imageSize, imageSize)];
            if ([[viewer objectForKey:@"facebook_id"] length]){
                [viewerButton setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
            } else {
                [viewerButton setImageWithURL:[viewer objectForKey:@"avatar_url"] forState:UIControlStateNormal];
            }
            viewerButton.titleLabel.text = [[viewer objectForKey:@"id"] stringValue];
            viewerButton.titleLabel.hidden = YES;
            
            [viewerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
            [viewerButton.imageView setBackgroundColor:[UIColor clearColor]];
            [viewerButton.imageView.layer setBackgroundColor:[UIColor clearColor].CGColor];
            viewerButton.imageView.layer.cornerRadius = 17.0;
            viewerButton.imageView.layer.shouldRasterize = YES;
            viewerButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            face.frame = CGRectMake((((space+imageSize)*index)+22),18,20,20);
            [cell.likersScrollView addSubview:viewerButton];
            for (NSDictionary *liker in likers) {
                if ([liker objectForKey:@"id"]){
                    if ([[liker objectForKey:@"id"] isEqualToNumber:[viewer objectForKey:@"id"]]){
                        [cell.likersScrollView addSubview:face];
                        break;
                    }
                }
            }

            index++;
        }
    }
    [cell.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    return cell;
}

-(void)profileTappedFromLikers:(id)sender {
    UIButton *button = (UIButton*)sender;
    FDProfileViewController *vc;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        vc = [storyboard5 instantiateViewControllerWithIdentifier:@"ProfileView"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    }
    [vc initWithUserId:button.titleLabel.text];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)profileTappedFromComment:(id)sender{
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}

-(void)profileTappedFromProfile:(id)sender {
    UIButton *button = (UIButton *) sender;
    FDProfileViewController *vc;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        UIStoryboard *storyboard5 = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
        vc = [storyboard5 instantiateViewControllerWithIdentifier:@"ProfileView"];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    }
    [vc initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowProfileFromProfile"]) {
        UIButton *button = (UIButton *) sender;
        FDProfileViewController *profileVC = segue.destinationViewController;
        [profileVC initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
    } else if ([segue.identifier isEqualToString:@"ShowPostFromProfile"]) {
        self.slidingViewController.panGesture.enabled = NO;
        FDPostViewController *vc = segue.destinationViewController;
        if ([sender isMemberOfClass:[UIButton class]]){
            UIButton *button = (UIButton *) sender;
            [vc setPostIdentifier:[NSString stringWithFormat:@"%d",button.tag]];
        } else {
            FDPost *post = (FDPost *) sender;
            [vc setPostIdentifier:post.identifier];
        }
    } else if ([segue.identifier isEqualToString:@"ShowProfileMap"]) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        FDProfileMapViewController *vc = segue.destinationViewController;
        [vc setUid:self.userId];
    } else if ([segue.identifier isEqualToString:@"ShowPlace"]){
        FDPlaceViewController *placeView = [segue destinationViewController];
        FDPost *post = (FDPost *) sender;
        [placeView setVenueId:post.foursquareid];
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - [(UITableView *)scrollView rowHeight]*10) {
        scrollView = nil;
        [self didShowLastRow];
    }
}

- (IBAction)showFollowers:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [[FDAPIClient sharedClient] getFollowers:self.userId success:^(id result) {
        self.followers = result;
        self.currentTab = 2;
        [self.postList reloadData];
    } failure:^(NSError *error) {

    }];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.followersButtonBackground setAlpha:1.0];
        [self.followerCountLabel setTextColor:[UIColor whiteColor]];
        [self.followersButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
    [self resetCategoryButtons];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView) {
        self.selectedVenue = [self.filteredUserVenues objectAtIndex:indexPath.row];
        [self.locationSearchDisplayController.searchBar setText:self.selectedVenue];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.locationSearchDisplayController.searchResultsTableView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.locationSearchDisplayController.searchResultsTableView setHidden:YES];
        }];
        
    } else if (self.filteredPosts.count > 0) {
        FDPost *selectedPost = (FDPost *)[self.filteredPosts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    } else if(indexPath.section == 0) {
        FDPost *selectedPost = (FDPost *)[self.posts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    }
}

- (IBAction)showFollowing:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [[FDAPIClient sharedClient] getFollowing:self.userId success:^(id result) {
        self.following = result;
        self.currentTab = 1;
        [self.postList reloadData];
    } failure:^(NSError *error) {

    }];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.followingButtonBackground setAlpha:1.0];
        [self.followingCountLabel setTextColor:[UIColor whiteColor]];
        [self.followingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
    [self resetCategoryButtons];
}

- (IBAction)showPosts:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.postsButtonBackground setAlpha:1.0];
        [self.postCountLabel setTextColor:[UIColor whiteColor]];
        [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
    self.currentTab = 0;
    self.canLoadMore = YES;
    [self resetCategoryButtons];
    [self loadPosts:self.userId];
}

-(void)resetStatButtonBackgrounds {
    [UIView animateWithDuration:.25 animations:^{
        [self.postsButtonBackground setAlpha:0.0];
        [self.followersButtonBackground setAlpha:0.0];
        [self.followingButtonBackground setAlpha:0.0];
        [self.postCountLabel setTextColor:[UIColor darkGrayColor]];
        [self.followerCountLabel setTextColor:[UIColor darkGrayColor]];
        [self.followingCountLabel setTextColor:[UIColor darkGrayColor]];
    }];

}

-(void)inviteUser:(NSString *)who {
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions", nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (!error) {
                // If permissions granted, publish the story
                [self inviteUserFb:who];
            }
        }];
    } else {
        // If permissions present, publish the story
        [self inviteUserFb:who];
    }
}

-(void)inviteUserFb:(NSString *)who {
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:self initialText:@"Download FOODIA. Spend less time with your phone and more time with your food." image:[UIImage imageNamed:@"blackLogo.png"] url:[NSURL URLWithString:@"http://www.foodia.com"] handler:^(FBNativeDialogResult result, NSError *error) {
        
        // Only show the error if it is not due to the dialog
        // not being supporte, i.e. code = 7, otherwise ignore
        // because our fallback will show the share view controller.
        if (error && [error code] == 7) {
            return;
            NSLog(@"there was an error code 7");
        }
        NSString *alertText = @"";
        if (error) {
            /*alertText = [NSString stringWithFormat:
             @"error: domain = %@, code = %d",
             error.domain, error.code];*/
        } else if (result == FBNativeDialogResultSucceeded) {
            alertText = @"Good going telling a friend about FOODIA! Why not tell another?";
        }
        if (![alertText isEqualToString:@""]) {
            // Show the result in an alert
            [[[UIAlertView alloc] initWithTitle:@"Thanks!"
                                        message:alertText
                                       delegate:self
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil] show];
        }
    }];
    
    if (!displayedNativeDialog) {

    }
}


- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [button setEnabled:NO];
    if ([post isLikedByUser]) {
        [[FDAPIClient sharedClient] unlikePost:post
                                       success:^(FDPost *newPost) {
                                           [button setEnabled:YES];
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                           [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }
         ];
        
    } else {
        [[FDAPIClient sharedClient] likePost:post
                                     success:^(FDPost *newPost) {
                                         [button setEnabled:YES];
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         
                                         //conditionally change the like count number
                                         int t = [newPost.likeCount intValue] + 1;
                                         if (!self.justLiked) [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         self.justLiked = YES;
                                         
                                         [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                         [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }
         ];
    }
}

- (void)loadAdditionalPosts{
    if (self.canLoadMore == YES && self.filteredPosts == 0){
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
        if (morePosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            [self.posts addObjectsFromArray:morePosts];
            NSLog(@"this is self.posts.count after additions: %d", self.posts.count);
            /*if (self.posts.count < [self.postCountLabel.text integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];*/
            [self.postList reloadData];
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
        NSLog(@"adding more profile posts has failed");
    }];
    }
}

- (void) didShowLastRow {
    if (self.posts.count && self.feedRequestOperation == nil && canLoadMore){
        [self loadAdditionalPosts];
    }
}

- (IBAction)getFeedForEating {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currentTab = 0;
    [self resetCategoryButtons];
    [self.eatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:kColorLightBlack];

    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Eating" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

- (IBAction)getFeedForDrinking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currentTab = 0;
    [self resetCategoryButtons];
    [self.drinkingButton setBackgroundColor:kColorLightBlack];
    [self.drinkingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Drinking" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (IBAction)getFeedForMaking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currentTab = 0;
    [self resetCategoryButtons];
    [self.makingButton setBackgroundColor:kColorLightBlack];
    [self.makingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Making" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (IBAction)getFeedForShopping {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self resetCategoryButtons];
    [self.shoppingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:kColorLightBlack];
    self.canLoadMore = NO;
    self.currentTab = 0;
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Shopping" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

-(void) resetCategoryButtons {
    [self.shoppingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor clearColor]];
    [self.makingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor clearColor]];
    [self.eatingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor clearColor]];
    [self.drinkingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor clearColor]];
    [self.drinkingButton setAlpha:1.0];
    [self.eatingButton setAlpha:1.0];
    [self.makingButton setAlpha:1.0];
    [self.shoppingButton setAlpha:1.0];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.makingButton.alpha = 0.0f;
        self.shoppingButton.alpha = 0.0f;
        self.drinkingButton.alpha = 0.0f;
        self.eatingButton.alpha = 0.0f;
        self.profileDetailsContainerView.alpha = 0.0f;
        if ([UIScreen mainScreen].bounds.size.height == 568){
            [self.postList setFrame:CGRectMake(0,88,320,460)];
        } else {
            [self.postList setFrame:CGRectMake(0,88,320,372)];
        }
    }];
    
}

-(void)doneEditing {
    [self.view endEditing:YES];
    [self.profileDetailsContainerView setHidden:NO];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.locationSearchBar setShowsCancelButton:NO animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self moveRight:self.searchBar withDelay:0];
        [self moveRight:self.locationSearchBar withDelay:.1];
        //self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
        self.makingButton.alpha = 1.0f;
        self.shoppingButton.alpha = 1.0f;
        self.drinkingButton.alpha = 1.0f;
        self.eatingButton.alpha = 1.0f;
        self.profileDetailsContainerView.alpha = 1.0f;
        [self.postList setFrame:self.postListRect];
        [self.postList setAlpha:1.0];
    }];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)thisSearchBar {
    self.currentTab = 0;
    [self.postSearchRequestOperation cancel];
    [self.view endEditing:YES];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self.filteredPosts removeAllObjects];
    [self.filteredUserVenues removeAllObjects];
    NSString *searchBarText;
    NSString *locationSearchText;
    if (self.searchBar.text.length > 0 && ![self.searchBar.text isEqualToString:searchBarPlaceholder]){
        searchBarText = [NSString stringWithFormat:@"%%%@%%",self.searchBar.text];
    } else {
        searchBarText = nil;
    }
    if (self.locationSearchBar.text.length > 0 && ![self.locationSearchBar.text isEqualToString:locationBarPlaceholder]){
        [self.geocoder geocodeAddressString:self.locationSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
            MKPlacemark *firstPlacemark = [placemarks objectAtIndex:0];
            self.location = [[CLLocation alloc] initWithLatitude:firstPlacemark.location.coordinate.latitude longitude:firstPlacemark.location.coordinate.longitude];
        }];
        locationSearchText = [NSString stringWithFormat:@"%%%@%%",self.locationSearchBar.text];
    }
    if (self.selectedVenue.length) {
        self.postSearchRequestOperation = [[FDAPIClient sharedClient] getUserPosts:self.userId forQuery:searchBarText withVenue:[NSString stringWithFormat:@"%%%@%%",self.selectedVenue] nearCoordinate:nil success:^(NSMutableArray *result) {
            if (result.count == 0) {
                self.noSearchResults = YES;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
            } else {
                self.noSearchResults = NO;
                self.filteredPosts = result;
                [self.postList setAlpha:1.0];
            }
            [self.postList reloadData];
            self.postSearchRequestOperation = nil;
        } failure:^(NSError *error) {
            NSLog(@"error from getuserposts method: %@", error.description);
            self.postSearchRequestOperation = nil;
        }];
    } else {
        NSLog(@"self selected venue: %@",self.selectedVenue);
        self.postSearchRequestOperation = [[FDAPIClient sharedClient] getUserPosts:self.userId forQuery:searchBarText withVenue:nil nearCoordinate:nil success:^(NSMutableArray *result) {
            if (result.count == 0) {
                self.noSearchResults = YES;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
            } else {
                self.noSearchResults = NO;
                self.filteredPosts = result;
                [self.postList setAlpha:1.0];
            }
            [self.postList reloadData];
            self.postSearchRequestOperation = nil;
        } failure:^(NSError *error) {
            NSLog(@"error from getuserposts method: %@", error.description);
            self.postSearchRequestOperation = nil;
        }];
    }
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.noSearchResults = NO;
    self.selectedVenue = nil;
    [self.filteredPosts removeAllObjects];
    [self.postList reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.location = nil;
    [self doneEditing];
}

-(void)moveLeft:(UISearchBar*)searchBar withDelay:(CGFloat)delay {
    [UIView animateWithDuration:.5 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
        searchBar.transform = CGAffineTransformMakeTranslation(-80, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            searchBar.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

-(void)moveRight:(UISearchBar*)searchBar withDelay:(CGFloat)delay {
    [UIView animateWithDuration:.75 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        searchBar.transform = CGAffineTransformMakeTranslation(320, 0);
    } completion:^(BOOL finished) {
        
    }];
}

-(IBAction)activateSearch {
    //[self loadAdditionalPosts];
    if (self.searchBar.frame.origin.x == 320){
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            if ([UIScreen mainScreen].bounds.size.height == 568){
                [self.postList setFrame:CGRectMake(0,88,320,460)];
            } else {
                [self.postList setFrame:CGRectMake(0,88,320,372)];
            }
            [self.postList setAlpha:.4];
            [self moveLeft:self.searchBar withDelay:0];
            [self moveLeft:self.locationSearchBar withDelay:.03];
            [self.editButton setHidden:YES];
            [self.profileDetailsContainerView setAlpha:0.0];
            //self.profileDetailsContainerView.frame = CGRectMake(0,40,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 0.0f;
            self.shoppingButton.alpha = 0.0f;
            self.drinkingButton.alpha = 0.0f;
            self.eatingButton.alpha = 0.0f;
            self.buttonBackground.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.profileDetailsContainerView setHidden:YES];
            self.userVenues = [NSArray array];
            [[FDAPIClient sharedClient] getVenuesForUser:self.userId success:^(id result) {
                self.userVenues = result;
            } failure:^(NSError *error) {
                NSLog(@"failure from getvenues: %@",error.description);
            }];
        }];
    } else {
        [self.profileDetailsContainerView setHidden:NO];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self moveRight:self.searchBar withDelay:0];
            [self moveRight:self.locationSearchBar withDelay:.05];
            [self.profileDetailsContainerView setAlpha:1.0];
            //self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 1.0f;
            self.shoppingButton.alpha = 1.0f;
            self.drinkingButton.alpha = 1.0f;
            self.eatingButton.alpha = 1.0f;
            [self.postList setFrame:self.postListRect];
            [self.editButton setHidden:NO];
            [self.postList setAlpha:1.0];
        }];
    }
}


- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    [self.slidingViewController anchorTopViewTo:ECRight];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate removeFacebookWallPost];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.feedRequestOperation = nil;
    self.objectSearchRequestOperation = nil;
    self.postSearchRequestOperation = nil;
    [super viewWillDisappear:animated];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
 
 //Update the filtered array based on the search text and scope.
    [self.filteredUserVenues removeAllObjects]; // First clear the filtered array.
 
 // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    for (NSString *venueName in self.userVenues) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:venueName]) {
            [self.filteredUserVenues addObject:venueName];
        }
    }
}


- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"search dispaly controller will start");
    [self.locationSearchDisplayController.searchResultsTableView setHidden:NO];
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.locationSearchDisplayController.searchResultsTableView setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchBar == self.locationSearchDisplayController.searchBar) {
        [self.locationSearchDisplayController.searchResultsTableView setHidden:NO];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.locationSearchDisplayController.searchResultsTableView setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
    //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
