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
#import "FDShareViewController.h"
#import "FDProfileMapViewController.h"
#import <FacebookSDK/FBSession.h>
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>
@interface FDProfileViewController()

@property (nonatomic) BOOL canLoadMore;
@property int tableViewHeight;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *activateSearchButton;
@property (nonatomic, weak) IBOutlet UIView *profileDetailsContainerView;
@property int *postListHeight;

@end

@implementation FDProfileViewController
@synthesize profileButton;
@synthesize postList;
//@synthesize posts;
@synthesize user;
@synthesize userId;
@synthesize profileContainerView;
@synthesize userNameLabel;
//@synthesize postButton, followersButton, followingButton;
//@synthesize inviteRequest;
@synthesize inactiveLabel;
@synthesize postCountLabel, followingCountLabel, followerCountLabel;
@synthesize feedRequestOperation;
@synthesize detailsRequestOperation;
@synthesize followers;
@synthesize following;
@synthesize currTab;
@synthesize currButton;
@synthesize canLoadMore;
@synthesize tableViewHeight;

- (void)initWithUserId:(NSString *)uid {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.userId = uid;
    NSLog(@"userId from profile view: %@",self.userId);
    self.canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        [profileButton setUserId:self.userId];
        currTab = 0;
        currButton = @"follow";
        self.followers = [NSArray array];
        self.following = [NSArray array];
        [self loadPosts:self.userId];
        [self.postList setHidden:false];
        [self.inactiveLabel setHidden:true];
        self.userNameLabel.text = [result objectForKey:@"name"];
        [self.userNameLabel setTextColor:[UIColor blackColor]];
        if([[NSString stringWithFormat:@"%@",[result objectForKey:@"active"]] isEqualToString:@"1"]) {
            self.postCountLabel.text = [[result objectForKey:@"posts_count"] stringValue];
            self.followingCountLabel.text = [[result objectForKey:@"following_count"] stringValue];
            self.followerCountLabel.text = [[result objectForKey:@"followers_count"] stringValue];
            if([[NSString stringWithFormat:@"%@",[result objectForKey:@"following"]] isEqualToString:@"1"]) {
                //self.navigationItem.rightBarButtonItem.title = @"UNFOLLOW";
                [self.socialButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor lightGrayColor]];
                [self.socialButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
                currButton = @"following";
            } else {
                //self.navigationItem.rightBarButtonItem.title = @"FOLLOW";
                [self.socialButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor redColor]];
                [self.socialButton.layer setBorderColor:[UIColor redColor].CGColor];
                currButton = @"follow";
            }
            self.followers = [result objectForKey:@"followers_arr"];
            self.following = [result objectForKey:@"following_arr"];
            [self.postList reloadData];
            //[self.postList reloadSections:[NSIndexSet indexSetWithIndexesInRange:{0,3}] withRowAnimation:<#(UITableViewRowAnimation)#> withRowAnimation:UITableViewRowAnimationFade];
        } else {
            //self.navigationItem.rightBarButtonItem.title = @"INVITE";
            [self.socialButton setTitle:@"INVITE" forState:UIControlStateNormal];
            [self.postList setHidden:true];
            [self.inactiveLabel setHidden:false];
            currButton = @"invite";
        }
    } failure:^(NSError *error) {

    }];
    
    self.user = nil;
    
}

-(IBAction)followButtonTapped {
    if([currButton isEqualToString:@"follow"]) {
        NSLog(@"Follow Tapped...");
        (void)[[FDAPIClient sharedClient] followUser:self.userId];
        //temporarily change follow number
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter+=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d",followerCounter];
        self.currButton = @"following";
        [self.socialButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    } else if([currButton isEqualToString:@"following"]) {
        NSLog(@"unfollowing Tapped...");
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter-=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d",followerCounter];
        
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
    //if (!self.userId)[self initWithUserId:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookID"]];
    currTab = 0;
    [self.navigationController setNavigationBarHidden:NO];
    self.mapView.layer.cornerRadius = 5.0f;
    self.mapView.clipsToBounds = YES;
    self.filteredPosts = [NSMutableArray array];
    self.followers = [NSArray array];
    self.following = [NSArray array];
    [self.postList setDataSource:self];
    [self.postList setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followCreated:) name:kNotificationFollowCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followDestroyed:) name:kNotificationFollowDestroyed object:nil];
    self.tableViewHeight = self.postList.frame.size.height;
    [self.searchDisplayController setDelegate:self];
    [self.searchDisplayController.searchBar setDelegate:self];
    self.searchDisplayController.searchBar.placeholder = @"Search for food, friends, places, etc";
    for (UIView *view in self.searchDisplayController.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        }
    }
    self.searchDisplayController.searchBar.showsScopeBar = YES;
    self.searchDisplayController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"ALL",@"Eat",@"Drink",@"Make",@"Shop",nil];
    self.searchDisplayController.searchBar.scopeBarBackgroundImage = [UIImage imageNamed:@"newFoodiaHeader.png"];
    self.socialButton.layer.borderWidth = 1.0f;
    self.socialButton.layer.cornerRadius = 16.0f;
    self.socialButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [TestFlight passCheckpoint:@"Passed Profile checkpoint"];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(revealMenu:)];
    if (self.navigationController.navigationBar.backItem == nil) {
        self.navigationItem.leftBarButtonItem = menuButton;
    }
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}


- (IBAction)done:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView != self.searchDisplayController.searchResultsTableView) return 3;
    else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredPosts.count;
    } else if(section == 0 && currTab == 0) {
        return self.posts.count;
    } else if(section == 1 && currTab == 1 && self.followers.count > 0 && self.following.count > 0) {
        return self.followers.count;
    } else if(section == 2 && currTab == 2 && self.following.count > 0 && self.followers.count > 0) {
        return self.following.count;
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 155;
    else return 44;
}

-(void)loadPosts:(NSString *)uid{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:uid success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self.postList reloadData];
    }];
    if (self.posts.count == 0) [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            FDPost *post = [self.filteredPosts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
        } else {
            FDPost *post = [self.posts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
            cell = [self showLikers:cell forPost:post];
            [cell bringSubviewToFront:cell.likersScrollView];
            if (post.location.coordinate.latitude != 0){
            }
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        }
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        
        return cell;
        
    } else if(indexPath.section == 1 && tableView != self.searchDisplayController.searchResultsTableView) {
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil];
            cell = (FDUserCell *)[nib objectAtIndex:0];
        }
        cell.nameLabel.text = [[self.followers objectAtIndex:indexPath.row] objectForKey:@"name"];
        [cell setFacebookId:[[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        [cell.button setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        peopleButton.tag = [[[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"] integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.imageFrame];
        return cell;
    } else if(indexPath.section == 2 && tableView != self.searchDisplayController.searchResultsTableView){
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil];
            cell = (FDUserCell *)[nib objectAtIndex:0];
        }
        cell.nameLabel.text = [[self.following objectAtIndex:indexPath.row] objectForKey:@"name"];
        [cell setFacebookId:[[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        [cell.button setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        peopleButton.tag = [[[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"] integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.imageFrame];
        return cell;
    } else {
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
    }
}

#pragma mark - Display likers

- (FDPostCell *)showLikers:(FDPostCell *)cell forPost:(FDPost *)post{
    NSDictionary *likers = post.likers;
    [cell.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.likersScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 36.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *liker in likers) {
        UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedLikeButtonRed.png"]];
        UIImageView *likerView = [[UIImageView alloc] initWithFrame:CGRectMake(((cell.likersScrollView.frame.origin.x)+((space+imageSize)*index)),(cell.likersScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *likerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
        likerButton.titleLabel.text = [liker objectForKey:@"facebook_id"];
        likerButton.titleLabel.hidden = YES;
        
        [likerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
        [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[liker objectForKey:@"facebook_id"]]];
        likerView.userInteractionEnabled = YES;
        likerView.clipsToBounds = YES;
        likerView.layer.cornerRadius = 5.0;
        likerView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
        heart.frame = CGRectMake((((space+imageSize)*index)+22),18,20,20);
        [likerButton setFrame:likerView.frame];
        heart.clipsToBounds = NO;
        [cell.likersScrollView addSubview:likerView];
        [cell.likersScrollView addSubview:heart];
        [cell.likersScrollView addSubview:likerButton];
        index++;
    }
    [cell.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    return cell;
}

-(void)profileTappedFromLikers:(id)sender {
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}



-(void)profileTappedFromProfile:(id)sender {
    UIButton *button = (UIButton *) sender;
    //[self performSegueWithIdentifier:@"ShowProfileFromProfile" sender:button];
    [self initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIButton *button = (UIButton *) sender;
    if ([segue.identifier isEqualToString:@"ShowProfileFromProfile"]) {
        FDProfileViewController *profileVC = segue.destinationViewController;
        [profileVC initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
    } else if ([segue.identifier isEqualToString:@"ShowPostFromProfile"]) {
        FDPostViewController *vc = segue.destinationViewController;
        [vc setPostIdentifier:[(FDPost *)sender identifier]];
    } else if ([segue.identifier isEqualToString:@"ShowProfileMap"]) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        FDProfileMapViewController *vc = segue.destinationViewController;
        NSLog(@"userID from profileView: %@",self.userId);
        [vc setUid:self.userId];
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
    self.currTab = 1;
    [self resetCategoryButtons];
    [self.postList reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        FDPost *selectedPost = (FDPost *)[self.filteredPosts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    } else if(indexPath.section == 0) {
        FDPost *selectedPost = (FDPost *)[self.posts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    }
}


- (IBAction)showFollowing:(id)sender {
    self.currTab = 2;
    [self resetCategoryButtons];
    [self.postList reloadData];
}

- (IBAction)showPosts:(id)sender {
    self.currTab = 0;
    self.canLoadMore = YES;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    [self resetCategoryButtons];
    //[self.postList reloadData];
    [self loadPosts:self.userId];
}

-(void)inviteUser:(NSString *)who {
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_stream"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_stream", @"email", nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
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
    UIViewController *vc = (UIViewController *)self;
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:vc initialText:@"Download FOODIA. Spend less time with your phone and more time with your food." image:[UIImage imageNamed:@"FOODIA_crab_114x114.png"] url:[NSURL URLWithString:@"http://www.foodia.com"] handler:^(FBNativeDialogResult result, NSError *error) {
        
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
                              otherButtonTitles:nil]
             show];
        }
    }];
    
    if (!displayedNativeDialog) {
        FDShareViewController *viewController =
        [[FDShareViewController alloc] initWithNibName:@"FDShareViewController"
                                                bundle:nil];
        viewController.recipient = who;
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    }

}


- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    
    if ([post isLikedByUser]) {
        [[FDAPIClient sharedClient] unlikePost:post
                                       success:^(FDPost *newPost) {
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                           [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }
         ];
        
    } else {
        [[FDAPIClient sharedClient] likePost:post
                                     success:^(FDPost *newPost) {
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         int t = [newPost.likeCount intValue] + 1;
                                         
                                         [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                         [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }
         ];
    }
}

- (void)loadAdditionalPosts{
    if (self.canLoadMore = YES){
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
        if (morePosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            [self.posts addObjectsFromArray:morePosts];
            NSLog(@"this is self.posts.count after additions: %d", self.posts.count);
            if (self.posts.count < [self.postCountLabel.text integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];
            [self.postList reloadData];
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
        NSLog(@"adding more profile posts has failed");
    }];
    } else {
        NSLog(@"can't load more");
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
    self.currTab = 0;
    [self resetCategoryButtons];
    [self.eatingButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor whiteColor]];

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
    self.currTab = 0;
    [self resetCategoryButtons];
    [self.drinkingButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor whiteColor]];

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
    self.currTab = 0;
    [self resetCategoryButtons];
    [self.makingButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor whiteColor]];
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
    [self.shoppingButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor whiteColor]];
    self.canLoadMore = NO;
    self.currTab = 0;
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
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.postList setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
    [self.postList setHidden:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.searchDisplayController.searchBar setFrame:CGRectMake(0,0,320,44)];
        self.profileButton.alpha = 0.0f;
        self.makingButton.alpha = 0.0f;
        self.shoppingButton.alpha = 0.0f;
        self.drinkingButton.alpha = 0.0f;
        self.eatingButton.alpha = 0.0f;
        self.profileDetailsContainerView.alpha = 0.0f;
    }];
    
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.filteredPosts removeAllObjects];
    [self.postList reloadData];
    [self.postList setHidden:NO];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.searchDisplayController.searchBar setFrame:CGRectMake(0,-44,320,44)];
        [self.searchDisplayController.searchBar setAlpha:0.0f];
        self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
        self.profileButton.alpha = 1.0f;
        self.makingButton.alpha = 1.0f;
        self.shoppingButton.alpha = 1.0f;
        self.drinkingButton.alpha = 1.0f;
        self.eatingButton.alpha = 1.0f;
        self.profileDetailsContainerView.alpha = 1.0f;
        [self.postList setFrame:CGRectMake(0,164,320,self.tableViewHeight)];
    }];
}

-(IBAction)activateSearch {
    [self loadAdditionalPosts];
    if (self.searchDisplayController.searchBar.alpha == 0.0f){
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.searchDisplayController.searchBar.alpha = 1.0f;
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0,0,320,44)];
            self.profileDetailsContainerView.frame = CGRectMake(0,44,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 0.0f;
            self.shoppingButton.alpha = 0.0f;
            self.drinkingButton.alpha = 0.0f;
            self.eatingButton.alpha = 0.0f;
            self.buttonBackground.alpha = 0.0f;
        }];
    } else {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.searchDisplayController.searchBar.alpha = 0.0f;
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0,-44,320,44)];
            self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 1.0f;
            self.shoppingButton.alpha = 1.0f;
            self.drinkingButton.alpha = 1.0f;
            self.eatingButton.alpha = 1.0f;
            self.buttonBackground.alpha = 1.0f;
        }];
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)originalScope
{
    //Update the filtered array based on the search text and scope.
    [self.filteredPosts removeAllObjects];
    NSString *scope;
    if (originalScope == @"Make") scope = @"Making";
    else scope = originalScope;
    NSLog(@"current scope: %@", scope);
    // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    if (scope == @"ALL"){
        for (FDPost *post in self.posts){
            NSString *combinedSearchBase = [NSString stringWithFormat:@"%@ %@", post.socialString, post.caption ];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:combinedSearchBase]) {
                [self.filteredPosts addObject:post];
            }
        }
    } else {
        for (FDPost *post in self.posts){
            NSMutableArray *predicateParts = [NSMutableArray arrayWithObjects:[NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText],[NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", scope],nil];
            NSPredicate *combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateParts];
            NSLog(@"predicate parts: %@",predicateParts);
            NSLog(@"combinedPredicate: %@", combinedPredicate);
            NSString *combinedSearchBase = [NSString stringWithFormat:@"%@ %@", post.socialString, post.caption ];
            if([combinedPredicate evaluateWithObject:combinedSearchBase]) {
                [self.filteredPosts addObject:post];
            }
        }
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
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
