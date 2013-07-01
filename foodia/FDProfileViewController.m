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
NSString* const foodPhilosophyPlaceholder = @"Your food philosophy";
NSString* const searchBarPlaceholder = @"Search for food and drink";
NSString* const myLocationBarPlaceholder = @"Search the places you've been";
NSString* const theirLocationBarPlaceholder = @"Search the places they've been";


@interface FDProfileViewController() <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate> {
    BOOL myProfile;
    BOOL canLoadMore;
    BOOL noSearchResults;
    BOOL justLiked;
    BOOL tableHeaderViewSet;
    CGRect postListRect;
    int postListHeight;
    int rowToReload;
    int currentTab;
    CLLocation *location;
    NSMutableArray *filteredUserVenues;
    NSArray *followers;
    NSArray *following;
    NSArray *userVenues;
    NSString *selectedVenue;
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *activateSearchButton;
@property (nonatomic, weak) IBOutlet UIView *profileDetailsContainerView;
@property (nonatomic, nonatomic) IBOutlet UIButton *profileButton;
@property (nonatomic, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *postList;
@property (weak, nonatomic)     IBOutlet UITextView *philosophyTextView;
@property (nonatomic,weak) IBOutlet UILabel *postCountLabel;
@property (nonatomic, weak) IBOutlet UIButton *socialButton;
@property (nonatomic, strong) IBOutlet UIButton *postButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
@property (nonatomic, strong) IBOutlet UIButton *followersButton;
@property (nonatomic,strong)         IBOutlet UILabel       *followerCountLabel;
@property (nonatomic,strong)         IBOutlet UILabel       *followingCountLabel;
@property (nonatomic,strong)         IBOutlet UILabel       *inactiveLabel;
@property (nonatomic, strong) AFHTTPRequestOperation *objectSearchRequestOperation;
@property (nonatomic, strong) AFHTTPRequestOperation *postSearchRequestOperation;
@property (weak, nonatomic) IBOutlet UIView *postsButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *followersButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *followingButtonBackground;
@property (strong, nonatomic) UISearchDisplayController *locationSearchDisplayController;
@property (strong, nonatomic) CLGeocoder *geocoder;

@end

@implementation FDProfileViewController
@synthesize profileButton, swipedCells;
@synthesize postList;
@synthesize posts, userId;
@synthesize userNameLabel;
@synthesize postCountLabel, followingCountLabel, followerCountLabel;
@synthesize feedRequestOperation, detailsRequestOperation, objectSearchRequestOperation, postSearchRequestOperation;
@synthesize geocoder = _geocoder;
@synthesize locationSearchDisplayController = _locationSearchDisplayController;

- (void)initWithUserId:(NSString *)uid {
    self.userId = uid;
    canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        if ([result objectForKey:@"id"])[self showPosts:[result objectForKey:@"id"]];
        if ([[result objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
            [profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:[result objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
        } else if ([result objectForKey:@"avatar_url"] != [NSNull null]) {
            [profileButton setImageWithURL:[NSURL URLWithString:[result objectForKey:@"avatar_url"]] forState:UIControlStateNormal];
        }
        followers = [NSArray array];
        following = [NSArray array];
        filteredUserVenues = [NSMutableArray array];
        
        [self.inactiveLabel setHidden:true];
        if ([result objectForKey:@"name"] != [NSNull null]) self.userNameLabel.text = [result objectForKey:@"name"];
        [self.userNameLabel setTextColor:[UIColor blackColor]];
        if([result objectForKey:@"active"]) {
            self.postCountLabel.text = [NSString stringWithFormat:@"%@ Posts",[[result objectForKey:@"post_count"] stringValue]];
            self.followingCountLabel.text = [NSString stringWithFormat:@"Following %@",[[result objectForKey:@"following_count"] stringValue]];
            self.followerCountLabel.text = [NSString stringWithFormat:@"%@ Followers",[[result objectForKey:@"follower_count"] stringValue]];
            
            [self.postCountLabel setHidden:NO];
            [self.followingCountLabel setHidden:NO];
            [self.followerCountLabel setHidden:NO];
            
            if (myProfile){
                [self.socialButton removeTarget:self action:@selector(followButtonTapped) forControlEvents:UIControlEventTouchUpInside];
                [self.socialButton addTarget:self action:@selector(editProfile) forControlEvents:UIControlEventTouchUpInside];
                [self.socialButton setTitle:@"Edit my profile" forState:UIControlStateNormal];
                [self.socialButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            } else if([result objectForKey:@"is_following"]) {
                [self.socialButton setTitle:kFollowing forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor lightGrayColor]];
                [self.socialButton setBackgroundImage:nil forState:UIControlStateNormal];
            } else {
                [self.socialButton setTitle:kFollow forState:UIControlStateNormal];
                [self.socialButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            }
            followers = [result objectForKey:@"followers_arr"];
            following = [result objectForKey:@"following_arr"];
            [self.postList reloadData];
        } else {
            [self.socialButton setTitle:@"Invite" forState:UIControlStateNormal];
            [self.postList setHidden:YES];
            [self.inactiveLabel setHidden:NO];
        }
        if ([[result objectForKey:@"philosophy"] length]){
            [self.philosophyTextView setText:[NSString stringWithFormat:@"\"%@\"",[result objectForKey:@"philosophy"]]];
            self.philosophyTextView.layer.cornerRadius = 5.0f;
            self.philosophyTextView.clipsToBounds = YES;
            //self.philosophyTextView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.4].CGColor;
            //self.philosophyTextView.layer.borderWidth = .5f;
            if (!tableHeaderViewSet) {
                CGRect philosophyRect = self.philosophyTextView.frame;
                philosophyRect.size.height += self.philosophyTextView.contentSize.height;
                [self.philosophyTextView setFrame:philosophyRect];
                CGRect detailsRect = self.profileDetailsContainerView.frame;
                detailsRect.size.height += self.philosophyTextView.frame.size.height;
                [self.profileDetailsContainerView setFrame:detailsRect];
                tableHeaderViewSet = YES;
            }
        } else {
            [self.philosophyTextView setHidden:YES];
        }
        postListRect = self.postList.frame;
        self.postList.tableHeaderView = self.profileDetailsContainerView;
        
    } failure:^(NSError *error) {}];
}

-(IBAction)followButtonTapped {
    if([self.socialButton.titleLabel.text isEqualToString:kFollow]) {
        [[FDAPIClient sharedClient] followUser:self.userId];
        //temporarily change follow number
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter+=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d Followers",followerCounter];
        [self.socialButton setTitle:kFollowing forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.socialButton setBackgroundImage:nil forState:UIControlStateNormal];
    } else if ([self.socialButton.titleLabel.text isEqualToString:kFollowing]) {
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter-=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d Followers",followerCounter];
        (void)[[FDAPIClient sharedClient] unfollowUser:self.userId];
        [self.socialButton setTitle:kFollow forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.socialButton setBackgroundImage:[UIImage imageNamed:@"profileBubble"] forState:UIControlStateNormal];
    } else if([self.socialButton.titleLabel.text isEqualToString:@"Invite"]) {
        [self inviteUser:self.userId];
        [self.socialButton setTitle:@"Invited" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.socialButton setBackgroundImage:nil forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [Flurry logPageView];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1.0]];
    self.geocoder = [[CLGeocoder alloc] init];
    [self.postList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //set up swiped cells thing
    self.swipedCells = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellClosed" object:nil];
    
    currentTab = 0;
    tableHeaderViewSet = NO;
    [self.navigationController setNavigationBarHidden:NO];
    
    self.profileButton.imageView.layer.cornerRadius = 38.0;
    [self.profileButton.imageView setBackgroundColor:[UIColor clearColor]];
    [self.profileButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.profileButton.imageView.layer.shouldRasterize = YES;
    self.profileButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    filteredPosts = [NSMutableArray array];
    followers = [NSArray array];
    following = [NSArray array];

    self.postsButtonBackground.layer.cornerRadius = 20.0;
    self.followersButtonBackground.layer.cornerRadius = 20.0;
    self.followingButtonBackground.layer.cornerRadius = 20.0;
    [self.searchBar setDelegate:self];
    [self.locationSearchBar setDelegate:self];
    self.searchBar.transform = CGAffineTransformMakeTranslation(320, 0);
    self.locationSearchBar.transform = CGAffineTransformMakeTranslation(320, 0);
    
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.locationSearchDisplayController = [self.searchDisplayController initWithSearchBar:self.locationSearchBar contentsController:self];
    [self.locationSearchDisplayController setDelegate:self];
    [self.locationSearchDisplayController setSearchResultsDataSource:self];
    [self.locationSearchDisplayController setSearchResultsDelegate:self];
    
    //set custom background for search bar
    for (UIView *view in self.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader"]];
            [view addSubview:header];
            break;
        }
    }
    //set custom background for search bar
    for (UIView *view in self.locationSearchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader"]];
            [view addSubview:header];
            break;
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kHelveticaNeueThin size:15];
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.locationSearchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kHelveticaNeueThin size:15];
        }
    }
    
    [self.followingButtonBackground setBackgroundColor:kColorLightBlack];
    [self.followersButtonBackground setBackgroundColor:kColorLightBlack];
    [self.postsButtonBackground setBackgroundColor:kColorLightBlack];
    [self.postCountLabel setTextColor:[UIColor whiteColor]];
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [super viewDidLoad];
    
    if ([self.userId isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        myProfile = YES;
        [self initWithUserId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        self.locationSearchBar.placeholder = myLocationBarPlaceholder;
    } else {
        self.locationSearchBar.placeholder = theirLocationBarPlaceholder;
    }
    self.searchBar.placeholder = searchBarPlaceholder;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostNotification:) name:@"UpdatePostNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPhilosophy) name:@"RefreshPhilosophy" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRowToReload:) name:@"RowToReloadFromMenu" object:nil];
}

- (void)setRowToReload:(NSNotification*) notification {
    NSString *postIdentifier = [notification.userInfo objectForKey:@"identifier"];
    for (FDPost *post in self.posts){
        if ([[NSString stringWithFormat:@"%@", post.identifier] isEqualToString:postIdentifier]){
            rowToReload = [self.posts indexOfObject:post];
            return;
        }
    }
    //post wasn't in this posts array, so make rowToReload inactive
    rowToReload = kRowToReloadInactive;
}

- (void)refreshPhilosophy{
    if (myProfile){
        self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] success:^(NSDictionary *result) {
            if ([[result objectForKey:@"philosophy"] length]){
                if ([[result objectForKey:@"philosophy"] isEqualToString:foodPhilosophyPlaceholder]) {
                    [self.philosophyTextView setText:@""];
                    [self.philosophyTextView setHidden:YES];
                } else {
                    [self.philosophyTextView setText:[NSString stringWithFormat:@"\"%@\"",[result objectForKey:@"philosophy"]]];
                    [self.philosophyTextView setHidden:NO];
                }
                
                self.philosophyTextView.layer.cornerRadius = 5.0f;
                self.philosophyTextView.clipsToBounds = YES;
                
                CGRect philosophyRect = self.philosophyTextView.frame;
                CGFloat philosophyHeightDifferential = (self.philosophyTextView.contentSize.height - self.philosophyTextView.frame.size.height);
                philosophyRect.size.height += (self.philosophyTextView.contentSize.height - self.philosophyTextView.frame.size.height);
                [self.philosophyTextView setFrame:philosophyRect];
                CGRect detailsRect = self.profileDetailsContainerView.frame;
                detailsRect.size.height += philosophyHeightDifferential;
                [self.profileDetailsContainerView setFrame:detailsRect];
                self.postList.tableHeaderView = self.profileDetailsContainerView;
                [self.postList reloadData];
            } else {
                [self.philosophyTextView setHidden:YES];
            }
        } failure:^(NSError *error) {}];
    }
}

- (void) updatePostNotification:(NSNotification *) notification {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        NSDictionary *userInfo = notification.userInfo;
        FDPost *postForReplacement = [userInfo objectForKey:@"post"];
        if (filteredPosts.count){
            [filteredPosts removeObjectAtIndex:rowToReload];
            [filteredPosts insertObject:postForReplacement atIndex:rowToReload];
        } else {
            [self.posts removeObjectAtIndex:rowToReload];
            [self.posts insertObject:postForReplacement atIndex:rowToReload];
        }
        
        NSIndexPath *indexPathToReload;
        indexPathToReload = [NSIndexPath indexPathForRow:rowToReload inSection:0];
        NSArray* rowsToReload = [NSArray arrayWithObjects:indexPathToReload, nil];
        if (filteredPosts.count){
            [self.postList reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.postList reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)editProfile {
    [self performSegueWithIdentifier:@"EditProfile" sender:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    noSearchResults = NO;
    self.slidingViewController.panGesture.enabled = NO;
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(revealMenu)];
    if (self.navigationController.navigationBar.backItem == nil) {
        self.navigationItem.leftBarButtonItem = menuButton;
    }
}

/*- (void)followCreated:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:YES] forKey:kIsFollwedBy];
    }
}

- (void)followDestroyed:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:NO] forKey:kIsFollwedBy];
    }
}*/

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
    //else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView && section == 0){
        return filteredUserVenues.count;
    } else if (filteredPosts.count > 0 && section == 0 && currentTab == 0) {
        return filteredPosts.count;
    } else if (noSearchResults && section == 0 && currentTab == 0) {
        return 1;
    } else if(section == 0 && currentTab == 0 && tableView != self.locationSearchDisplayController.searchResultsTableView) {
        return self.posts.count;
    } else if(section == 1 && currentTab == 1 && tableView != self.locationSearchDisplayController.searchResultsTableView) {

        return following.count;
    } else if(section == 2 && currentTab == 2 && tableView != self.locationSearchDisplayController.searchResultsTableView) {
        return followers.count;
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
            [UIView animateWithDuration:.25 animations:^{
                [self.socialButton setAlpha:1.0];
                [self.postsButtonBackground setAlpha:1.0];
            }];
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        self.feedRequestOperation = nil;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView) {
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationCell"];
        NSString *locationName = (NSString*)[filteredUserVenues objectAtIndex:indexPath.row];
        [cell.textLabel setText:locationName];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15.0]];
        return cell;
    } else if (indexPath.section == 0 && !noSearchResults) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        FDPost *post;
        if (filteredPosts.count > 0) {
            post = [filteredPosts objectAtIndex:indexPath.row];
        } else {
            post = [self.posts objectAtIndex:indexPath.row];
        }
        [cell configureForPost:post];
        cell = [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        cell.detailPhotoButton.tag = indexPath.row;
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        cell.recButton.tag = indexPath.row;

        cell.commentButton.tag = indexPath.row;
        [cell.commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        //capture touch event to show user place map
        if (post.locationName.length){
            [cell.locationButton setHidden:NO];
            [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
            cell.locationButton.tag = indexPath.row;
        }
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        
        //swipe cell accordingly
        if ([self.swipedCells indexOfObject:post.identifier] != NSNotFound){
            [cell.scrollView setContentOffset:CGPointMake(271,0)];
        } else [cell.scrollView setContentOffset:CGPointZero];
        
        if (cell.scrollView.contentOffset.x > 270) {
            [cell.slideCellButton setHidden:NO];
        } else {
            [cell.slideCellButton setHidden:YES];
        }
        return cell;
    } else if (indexPath.section == 1) {
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil] lastObject];
        }
        FDUser *thisUser = [following objectAtIndex:indexPath.row];
        [cell configureForUser:thisUser];
        [cell.nameLabel setText:thisUser.name];
        
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
        FDUser *thisUser = [followers objectAtIndex:indexPath.row];
        cell.nameLabel.text = thisUser.name;
        [cell configureForUser:thisUser];
        [cell.actionButton setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        
        peopleButton.tag = [thisUser.userId integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.profileButton.frame];
        return cell;
    } else {
        [self.locationSearchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.postList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        [emptyCell.textLabel setText:@"No Results"];
        [emptyCell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [emptyCell.textLabel setTextColor:[UIColor lightGrayColor]];
        [emptyCell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:20.0]];
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostCell class]]){
        FDPostCell *thisCell = (FDPostCell*)cell;
        [UIView animateWithDuration:.25 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
            [thisCell.photoImageView setAlpha:0.0];
            [thisCell.posterButton setAlpha:0.0];
        }];
    }
}

//take care of swiped cells
- (void)swipedCells:(NSNotification*)notification {
    NSString *identifier = [notification.userInfo objectForKey:@"identifier"];
    if ([self.swipedCells indexOfObject:identifier] == NSNotFound){
        [self.swipedCells addObject:identifier];
    } else {
        [self.swipedCells removeObject:identifier];
    }
}

- (void)didSelectRow:(UIButton*)button {
    rowToReload = button.tag;
    FDPost *post;
    if (filteredPosts.count){
        post = [filteredPosts objectAtIndex:button.tag];
    } else {
        post = [self.posts objectAtIndex:button.tag];
    }
    [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:post];
}

-(void)showPlace:(UIButton*)button {
    if ([button.titleLabel.text isEqualToString:@"Home"] || [button.titleLabel.text isEqualToString:@"home"]) {
        if (myProfile){
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Sorry, but we don't collect information about your home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        } else{
            [[[UIAlertView alloc] initWithTitle:@"" message:@"We don't share information about anyone's home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }
    } else {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        if (filteredPosts.count > 0) {
            [self performSegueWithIdentifier:@"ShowPlaceFromProfile" sender:[filteredPosts objectAtIndex:button.tag]];
        } else {
            [self performSegueWithIdentifier:@"ShowPlaceFromProfile" sender:[self.posts objectAtIndex:button.tag]];
        }
    }
}

- (void)recommend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    FDCustomSheet *actionSheet;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA", @"Recommend via Facebook",kSendText, kSendEmail, nil];
    } else {
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA", kSendText, kSendEmail, nil];
    }
     
    [actionSheet setFoodiaObject:post.foodiaObject];
    [actionSheet setPost:post];
    [actionSheet showInView:self.view];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! ([touch.view isKindOfClass:[UIControl class]]);
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
            if ([[viewer objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
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
        FDPost *post = (FDPost *) sender;
        [vc setPostIdentifier:post.identifier];
    } else if ([segue.identifier isEqualToString:@"ShowProfileMap"]) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        FDProfileMapViewController *vc = segue.destinationViewController;
        [vc setUid:self.userId];
    } else if ([segue.identifier isEqualToString:@"ShowPlaceFromProfile"]){
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
        followers = result;
        currentTab = 2;
        [self.postList reloadData];
    } failure:^(NSError *error) {

    }];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.followersButtonBackground setAlpha:1.0];
        [self.followerCountLabel setTextColor:[UIColor whiteColor]];
        [self.followersButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.locationSearchDisplayController.searchResultsTableView) {
        selectedVenue = [filteredUserVenues objectAtIndex:indexPath.row];
        [self.locationSearchDisplayController.searchBar setText:selectedVenue];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.locationSearchDisplayController.searchResultsTableView setAlpha:0.0];
        } completion:^(BOOL finished) {
            
        }];
        
    } else if (filteredPosts.count) {
        FDPost *selectedPost = (FDPost *)[filteredPosts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    } else if(indexPath.section == 0 && self.posts.count) {
        FDPost *selectedPost = (FDPost *)[self.posts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    }
}

- (IBAction)showFollowing:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [[FDAPIClient sharedClient] getFollowing:self.userId success:^(id result) {
        following = result;
        currentTab = 1;
        [self.postList reloadData];
    } failure:^(NSError *error) {

    }];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.followingButtonBackground setAlpha:1.0];
        [self.followingCountLabel setTextColor:[UIColor whiteColor]];
        [self.followingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
}

- (IBAction)showPosts:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self resetStatButtonBackgrounds];
    [UIView animateWithDuration:.25 animations:^{
        [self.postsButtonBackground setAlpha:1.0];
        [self.postCountLabel setTextColor:[UIColor whiteColor]];
        [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
    currentTab = 0;
    canLoadMore = YES;
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
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:self initialText:@"Download FOODIA. Spend less time with your phone and more time with good food." image:[UIImage imageNamed:@"blackLogo.png"] url:[NSURL URLWithString:@"http://www.foodia.com"] handler:^(FBNativeDialogResult result, NSError *error) {
        
        // Only show the error if it is not due to the dialog
        // not being supporte, i.e. code = 7, otherwise ignore
        // because our fallback will show the share view controller.
        if (error && [error code] == 7) {
            return;
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
        [UIView animateWithDuration:.35 animations:^{
            [button setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
        }];
        [[FDAPIClient sharedClient] unlikePost:post
                                        detail:NO
                                       success:^(FDPost *newPost) {
                                           [button setEnabled:YES];
                                           justLiked = NO;
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                           [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }
         ];
        
    } else {
        [UIView animateWithDuration:.35 animations:^{
            [button setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
        }];
        [[FDAPIClient sharedClient] likePost:post
                                      detail:NO
                                     success:^(FDPost *newPost) {
                                         [button setEnabled:YES];
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         
                                         //conditionally change the like count number
                                         int t = [newPost.likeCount intValue] + 1;
                                         if (!justLiked) [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         justLiked = YES;
                                         
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
    if (canLoadMore == YES && filteredPosts.count == 0){
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
            if (morePosts.count == 0){
                canLoadMore = NO;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            } else {
                [self.posts addObjectsFromArray:morePosts];
                /*if (self.posts.count < [self.postCountLabel.text integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];*/
                [self.postList reloadData];
            }
            self.feedRequestOperation = nil;
        } failure:^(NSError *error){
            self.feedRequestOperation = nil;

        }];
    }
}

- (void) didShowLastRow {
    if (self.posts.count && self.feedRequestOperation == nil && canLoadMore){
        [self loadAdditionalPosts];
    }
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    //postlist should fill the height left by hiding the navigation bar
    postListRect.size.height += 44;
    [self.postList setFrame:postListRect];
    if (searchBar == self.locationSearchBar) {
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.locationSearchDisplayController.searchResultsTableView setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }
}

-(void)doneEditing {
    [self.view endEditing:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.locationSearchBar setShowsCancelButton:NO animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self moveRight:self.searchBar withDelay:0];
        [self moveRight:self.locationSearchBar withDelay:.1];
        [self.postList setAlpha:1.0];
    }];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)thisSearchBar {
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.locationSearchDisplayController.searchResultsTableView setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
    currentTab = 0;
    self.postSearchRequestOperation = nil;
    [self.view endEditing:YES];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [filteredPosts removeAllObjects];
    [filteredUserVenues removeAllObjects];
    NSString *searchBarText;
    NSString *locationSearchText;
    if (self.searchBar.text.length > 0 && ![self.searchBar.text isEqualToString:searchBarPlaceholder]){
        searchBarText = [NSString stringWithFormat:@"%%%@%%",self.searchBar.text];
    } else {
        searchBarText = @"";
    }
    if (![self.locationSearchBar.text isEqualToString:theirLocationBarPlaceholder] || ![self.locationSearchBar.text isEqualToString:theirLocationBarPlaceholder]){
        if (self.locationSearchBar.text.length > 0){
            [self.geocoder geocodeAddressString:self.locationSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
                if (placemarks.count){
                    MKPlacemark *firstPlacemark = [placemarks objectAtIndex:0];
                    location = [[CLLocation alloc] initWithLatitude:firstPlacemark.location.coordinate.latitude longitude:firstPlacemark.location.coordinate.longitude];
                }
            }];
            locationSearchText = [NSString stringWithFormat:@"%%%@%%",self.locationSearchBar.text];
        }
    }
    if (selectedVenue.length) {
        self.postSearchRequestOperation = [[FDAPIClient sharedClient] getUserPosts:self.userId forQuery:searchBarText withVenue:[NSString stringWithFormat:@"%%%@%%",selectedVenue] nearCoordinate:nil success:^(NSMutableArray *result) {
            if (result.count == 0) {
                noSearchResults = YES;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
            } else {
                noSearchResults = NO;
                filteredPosts = result;
                [self.postList setAlpha:1.0];
            }
            [self.postList reloadData];
            self.postSearchRequestOperation = nil;
        } failure:^(NSError *error) {
            self.postSearchRequestOperation = nil;
        }];
    } else {
        self.postSearchRequestOperation = [[FDAPIClient sharedClient] getUserPosts:self.userId forQuery:searchBarText withVenue:nil nearCoordinate:nil success:^(NSMutableArray *result) {
            if (result.count == 0) {
                noSearchResults = YES;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
            } else {
                noSearchResults = NO;
                filteredPosts = result;
                [self.postList setAlpha:1.0];
            }
            [self.postList reloadData];
            self.postSearchRequestOperation = nil;
        } failure:^(NSError *error) {
            self.postSearchRequestOperation = nil;
        }];
    }
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    noSearchResults = NO;
    selectedVenue = @"";
    [filteredPosts removeAllObjects];
    [self.postList reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self doneEditing];
    postListRect.size.height = self.view.frame.size.height;
    [self.postList setFrame:postListRect];
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
            [self.postList setAlpha:.4];
            [self moveLeft:self.searchBar withDelay:0];
            [self moveLeft:self.locationSearchBar withDelay:.03];
            [self.searchBar setAlpha:1.0];
            [self.locationSearchBar setAlpha:1.0];
        } completion:^(BOOL finished) {
            userVenues = [NSArray array];
            [[FDAPIClient sharedClient] getVenuesForUser:self.userId success:^(id result) {
                userVenues = result;
            } failure:^(NSError *error) {
            }];
        }];
    } else {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self moveRight:self.searchBar withDelay:0];
            [self moveRight:self.locationSearchBar withDelay:.05];
            [self.postList setAlpha:1.0];
            [self.searchBar setAlpha:0.0];
            [self.locationSearchBar setAlpha:0.0];
        }];
    }
}


- (void)revealMenu {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    [self.slidingViewController anchorTopViewTo:ECRight];
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
    [filteredUserVenues removeAllObjects]; // First clear the filtered array.
 
 // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    for (NSString *venueName in userVenues) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:venueName]) {
            [filteredUserVenues addObject:venueName];
        }
    }
}


- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    /*[self.locationSearchDisplayController.searchResultsTableView setHidden:NO];
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.locationSearchDisplayController.searchResultsTableView setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
    */
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    /*if (searchBar == self.locationSearchDisplayController.searchBar) {
        [self.locationSearchDisplayController.searchResultsTableView setHidden:NO];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.locationSearchDisplayController.searchResultsTableView setAlpha:1.0];
        } completion:^(BOOL finished) {
            
        }];
    }*/
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
