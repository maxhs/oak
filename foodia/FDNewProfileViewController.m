//
//  FDNewProfileViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/16/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDNewProfileViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "FDAppDelegate.h"
#import "FDPostCell.h"
#import "FDProfileCell.h"
#import "FDProfileMapViewController.h"
#import "FDFeedViewController.h"

@interface FDNewProfileViewController ()
@property (nonatomic) BOOL canLoadMore;
@property int tableViewHeight;
@property int *postListHeight;

@end

@implementation FDNewProfileViewController

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
@synthesize profileImageView, postCountLabel, followingCountLabel, followerCountLabel;
@synthesize feedRequestOperation;
@synthesize detailsRequestOperation;
@synthesize followers;
@synthesize following;
@synthesize currTab;
@synthesize currButton;
@synthesize canLoadMore;
@synthesize tableViewHeight;

- (void)initWithUserId:(NSString *)uid {
    NSLog(@"initializing profile with uid: %@",uid);
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.userId = uid;
    self.canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        [profileButton setUserId:self.userId];
        currTab = 0;
        currButton = @"follow";
        self.followers = [NSArray array];
        self.following = [NSArray array];
        [self refresh];
        [self.postList setHidden:false];
        [self.inactiveLabel setHidden:true];
        self.userNameLabel.text = [result objectForKey:@"name"];
        if([[NSString stringWithFormat:@"%@",[result objectForKey:@"active"]] isEqualToString:@"1"]) {
            self.postCountLabel = [[result objectForKey:@"posts_count"] stringValue];
            self.followingCountLabel = [[result objectForKey:@"following_count"] stringValue];
            self.followerCountLabel = [[result objectForKey:@"followers_count"] stringValue];
            if([[NSString stringWithFormat:@"%@",[result objectForKey:@"following"]] isEqualToString:@"1"]) {
                self.navigationItem.rightBarButtonItem.title = @"UNFOLLOW";
                currButton = @"following";
            } else {
                self.navigationItem.rightBarButtonItem.title = @"FOLLOW";
                currButton = @"follow";
            }
            self.followers = [result objectForKey:@"followers_arr"];
            self.following = [result objectForKey:@"following_arr"];
            [self.postList reloadData];
            //[self.postList reloadSections:[NSIndexSet indexSetWithIndexesInRange:{0,3}] withRowAnimation:<#(UITableViewRowAnimation)#> withRowAnimation:UITableViewRowAnimationFade];
        } else {
            self.navigationItem.rightBarButtonItem.title = @"INVITE";
            [self.postList setHidden:true];
            [self.inactiveLabel setHidden:false];
            currButton = @"invite";
        }
    } failure:^(NSError *error) {
        
    }];
    self.user = nil;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        }
    }
    FDFeedViewController *vc = (FDFeedViewController *)self.parentViewController;
    vc.searchBar.showsScopeBar = YES;
    self.searchDisplayController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"ALL",@"Eat",@"Drink",@"Make",@"Shop",nil];
    self.searchDisplayController.searchBar.scopeBarBackgroundImage = [UIImage imageNamed:@"foodiaHeader.png"];

}

- (void)showMapView {
    UIStoryboard*  sb;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        sb = [UIStoryboard storyboardWithName:@"iPhone5"
                                       bundle:nil];
    } else {
        sb = [UIStoryboard storyboardWithName:@"iPhone"
                                       bundle:nil];
    }
    FDProfileMapViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ProfileMapView"];
    [vc setUid:self.userId];
    NSLog(@"userId for mapview: %@", vc.uid);
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh{
    if(!self.isLoading) {
        self.isLoading = YES;
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:self.userId success:^(NSMutableArray *newPosts) {
            self.posts = newPosts;
            [self.postList reloadData];
            NSLog(@"success with loadPosts from new profile");
            self.feedRequestOperation = nil;
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self.postList reloadData];
        }];
        if (self.posts.count == 0) [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    //if([self.posts count] != 0) [self refresh];
    //else [self loadFromCache];
    [self refresh];
    [super.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 80;
    else return 155;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        //for profile stuff
        return 1;
    } else /*if (section == 1)*/ {
        return self.posts.count;
        NSLog(@"number of profile posts: %d", self.posts.count);
    //} else if (self.posts.count == 0) {
    //    return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *ProfileCellIdentifier = @"ProfileCell";
        FDProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:ProfileCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDProfileCell" owner:self options:nil];
            cell = (FDProfileCell *)[nib objectAtIndex:0];
            [cell.profileButton setUserId:self.userId];
            cell.followerCountLabel.text = self.followerCountLabel;
            cell.followingCountLabel.text = self.followingCountLabel;
            cell.postCountLabel.text = self.postCountLabel;
        }
        [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(showActivity) forControlEvents:UIControlEventTouchUpInside];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        UIButton *mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect mapRect = cell.mapView.frame;
        [mapButton setFrame:mapRect];
        [mapButton addTarget:self action:@selector(showMapView) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:mapButton];
        cell.mapView.layer.cornerRadius = 5.0f;
        cell.mapView.clipsToBounds = YES;
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = cell.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        [cell.locationButton addTarget:self action:@selector(selectMap:) forControlEvents:UIControlEventTouchUpInside];
        cell.locationButton.tag = indexPath.row;
        
        UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recButton setFrame:CGRectMake(278,52,70,34)];
        [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        [recButton setTitle:@"REC" forState:UIControlStateNormal];
        [recButton setTitle:@"REC" forState:UIControlStateSelected];
        recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        recButton.layer.borderWidth = 1.0f;
        recButton.backgroundColor = [UIColor whiteColor];
        recButton.layer.cornerRadius = 17.0f;
        [recButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        recButton.tag = indexPath.row;
        [cell.scrollView addSubview:recButton];
        
        UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commentButton setFrame:CGRectMake(278,97,130,34)];
        commentButton.tag = indexPath.row;
        [commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        [commentButton setTitle:@"Add a comment..." forState:UIControlStateNormal];
        [commentButton setTitle:@"Nice!" forState:UIControlStateSelected];
        commentButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        commentButton.layer.borderWidth = 1.0f;
        commentButton.backgroundColor = [UIColor whiteColor];
        commentButton.layer.cornerRadius = 17.0f;
        [commentButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [commentButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        
        cell.detailPhotoButton.tag = indexPath.row;
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.scrollView addSubview:commentButton];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        
        return cell;
    }
   /* } else {
        static NSString *FeedLoadingCellIdentifier = @"FeedLoadingCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedLoadingCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FeedLoadingCell" owner:self options:nil];
            cell = (FDPostCell *) [nib objectAtIndex:0];
        }
        
        return cell;
        NSLog(@"end cell section");
         static NSString *FeedEndCellIdenfitier = @"FeedEndCellIdenfitier";
         UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedEndCellIdenfitier];
         if (cell == nil) {
         NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FeedEndCell" owner:self options:nil];
         cell = (FDPostCell *)[nib objectAtIndex:0];
         }
         [cell.contentView setHidden:YES];
         if(self.fewPosts = FALSE){
         NSLog(@"fewPosts is true from postTable");
         [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(showFeaturedPosts) forControlEvents:UIControlEventTouchUpInside];
         [((UIButton *)[cell viewWithTag:2]) addTarget:self action:@selector(showSocial) forControlEvents:UIControlEventTouchUpInside];
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
         [cell setHidden:NO];
         }
         return cell;*/
    return 0;
}

- (void)loadAdditionalPosts {
    if (self.canLoadMore == YES) {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
            if (morePosts.count == 0){
                self.canLoadMore = NO;
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            } else {
                [self.posts addObjectsFromArray:morePosts];
                NSLog(@"this is self.posts.count after additions: %d", self.posts.count);
                if (self.posts.count < [self.postCountLabel integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];
                [self.postList reloadData];
            }
            self.feedRequestOperation = nil;
        } failure:^(NSError *error){
            self.feedRequestOperation = nil;
            NSLog(@"adding more profile posts has failed");
        }];
    } else {
        NSLog(@"can't load more");
    }}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) [self loadAdditionalPosts];
}

- (void)activateSearch {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HideSlider" object:nil];
}

-(IBAction)followButtonTapped {
    
    if([currButton isEqualToString:@"follow"] || [self.navigationItem.rightBarButtonItem.title isEqual: @"FOLLOW"]) {
        NSLog(@"Follow Tapped...");
        (void)[[FDAPIClient sharedClient] followUser:self.userId];
        //temporarily change follow number
        int followerCounter;
        followerCounter = [followerCountLabel integerValue];
        followerCounter+=1;
        followerCountLabel = [NSString stringWithFormat:@"%d",followerCounter];
        
        [self.navigationItem.rightBarButtonItem setTitle:@"UNFOLLOW"];
        self.currButton = @"following";
    } else if([currButton isEqualToString:@"following"] || [self.navigationItem.rightBarButtonItem.title isEqualToString:@"UNFOLLOW"]) {
        NSLog(@"unfollowing Tapped...");
        int followerCounter;
        followerCounter = [followerCountLabel integerValue];
        followerCounter-=1;
        followerCountLabel = [NSString stringWithFormat:@"%d",followerCounter];
        (void)[[FDAPIClient sharedClient] unfollowUser:self.userId];
        
        [self.navigationItem.rightBarButtonItem setTitle:@"FOLLOW"];
        self.currButton = @"follow";
    } else if([currButton isEqualToString:@"invite"] || [self.navigationItem.rightBarButtonItem.title isEqualToString: @"INVITE"]) {
        NSLog(@"Invite Tapped...");
        [self.navigationItem.rightBarButtonItem setTitle:@"INVITED"];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.filteredPosts removeAllObjects];
    //[self.posts removeAllObjects];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

-(void)loadPosts:(NSString *)uid{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:uid success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        [self.postList reloadData];
        NSLog(@"success with loadPosts from profile");
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self.postList reloadData];
    }];
    if (self.posts.count == 0) [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

-(void)profileTappedFromProfile:(id)sender {
    UIButton *button = (UIButton *) sender;
    //[self performSegueWithIdentifier:@"ShowProfileFromProfile" sender:button];
    [self initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
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
    [self.postList reloadData];
}

- (IBAction)showPosts:(id)sender {
    self.currTab = 0;
    self.canLoadMore = YES;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    //[self.postList reloadData];
    [self loadPosts:self.userId];
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

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)originalScope
{
    //Update the filtered array based on the search text and scope.
    [self.filteredPosts removeAllObjects];
    NSString *scope;
    if ([originalScope isEqualToString:@"Make"]) scope = @"Making";
    else scope = originalScope;
    NSLog(@"current scope: %@", scope);
    // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    if ([scope isEqual: @"ALL"]){
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
