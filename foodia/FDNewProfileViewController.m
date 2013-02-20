//
//  FDNewProfileViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/16/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDNewProfileViewController.h"
#import "Facebook.h"
#import "FDAppDelegate.h"
#import "FDPostCell.h"
#import "FDProfileCell.h"
#import "FDProfileMapViewController.h"
#import "FDFeedViewController.h"
#import "Utilities.h"

@interface FDNewProfileViewController ()
@property (nonatomic) BOOL canLoadMore;
@property int tableViewHeight;

@end

@implementation FDNewProfileViewController

@synthesize profileButton;
@synthesize user;
@synthesize userId;
//@synthesize postButton, followersButton, followingButton;
@synthesize feedRequestOperation;
@synthesize detailsRequestOperation;
@synthesize followers;
@synthesize following;
@synthesize currTab;
@synthesize currButton;
@synthesize canLoadMore;
@synthesize tableViewHeight;

- (void)initWithUserId:(NSString *)uid {
    //[(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.userId = uid;
    self.canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        [profileButton setUserId:self.userId];
        currTab = 0;
        currButton = @"follow";
        self.followers = [NSArray array];
        self.following = [NSArray array];
        [self refresh];
        [self.tableView setHidden:false];
        if([[NSString stringWithFormat:@"%@",[result objectForKey:@"active"]] isEqualToString:@"1"]) {
            self.postCountLabel = [[result objectForKey:@"posts_count"] stringValue];
            self.followingCountLabel = [[result objectForKey:@"following_count"] stringValue];
            self.followerCountLabel = [[result objectForKey:@"followers_count"] stringValue];
            if([[NSString stringWithFormat:@"%@",[result objectForKey:@"following"]] isEqualToString:@"1"]) {
                currButton = @"following";
            } else {
                currButton = @"follow";
            }
            self.followers = [result objectForKey:@"followers_arr"];
            self.following = [result objectForKey:@"following_arr"];
            [self.tableView reloadData];
        } else {
            [self.tableView setHidden:true];
            currButton = @"invite";
        }
    } failure:^(NSError *error) {
        
    }];
    self.user = nil;

}

- (void)viewDidLoad
{
    //[super viewDidLoad];
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
    [self refresh];
    [self reloadData];
    
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
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:self.userId success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        [self reloadData];
        NSLog(@"success with loadPosts from new profile");
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
    }];
    if (self.posts.count == 0) [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)viewDidAppear:(BOOL)animated {
    //if([self.posts count] != 0) [self refresh];
    //else [self loadFromCache];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 112;
    else return 155;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        //for profile stuff
        return 1;
    } else if(section == 0 && currTab == 0) {
        return self.posts.count;
    } else if(section == 1 && currTab == 1 && self.followers.count > 0 && self.following.count > 0) {
        return self.followers.count;
    } else {
        return self.following.count;
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
            cell.makingButton.layer.cornerRadius = 17.0;
            cell.eatingButton.layer.cornerRadius = 17.0;
            cell.drinkingButton.layer.cornerRadius = 17.0;
            cell.shoppingButton.layer.cornerRadius = 17.0;
            [cell.followersButton addTarget:self action:@selector(showFollowers) forControlEvents:UIControlEventTouchUpInside];
            [cell.followingButton addTarget:self action:@selector(showFollowing) forControlEvents:UIControlEventTouchUpInside];
            [cell.eatingButton addTarget:self action:@selector(getFeedForEating) forControlEvents:UIControlEventTouchUpInside];
            [cell.drinkingButton addTarget:self action:@selector(getFeedForDrinking) forControlEvents:UIControlEventTouchUpInside];
            [cell.makingButton addTarget:self action:@selector(getFeedForMaking) forControlEvents:UIControlEventTouchUpInside];
            [cell.shoppingButton addTarget:self action:@selector(getFeedForShopping) forControlEvents:UIControlEventTouchUpInside];
        }
        [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(showActivity) forControlEvents:UIControlEventTouchUpInside];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        cell = [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = cell.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        //capture touch event to show user place map
        if (post.locationName.length){
            [cell.locationButton setHidden:NO];
            [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
            cell.locationButton.tag = indexPath.row;
        }
        
        UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recButton setFrame:CGRectMake(276,52,70,34)];
        [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        [recButton setTitle:@"Rec" forState:UIControlStateNormal];
        recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        recButton.layer.borderWidth = 1.0f;
        recButton.backgroundColor = [UIColor whiteColor];
        recButton.layer.cornerRadius = 17.0f;
        [recButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        recButton.tag = indexPath.row;
        [cell.scrollView addSubview:recButton];
        
        UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commentButton setFrame:CGRectMake(382,52,118,34)];
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


- (void)loadAdditionalPosts {
    if (self.canLoadMore == YES) {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
            if (morePosts.count == 0){
                self.canLoadMore = NO;
            } else {
                [self.posts addObjectsFromArray:morePosts];
                if (self.posts.count < [self.postCountLabel integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];
                [self.tableView reloadData];
            }
            self.feedRequestOperation = nil;
        } failure:^(NSError *error){
            self.feedRequestOperation = nil;
            NSLog(@"adding more profile posts has failed");
        }];
    }
}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) [self loadAdditionalPosts];
}

- (void)activateSearch {
    NSLog(@"activate search was tapped");
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

-(void)loadPosts:(NSString *)uid{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:uid success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        [self.tableView reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
    }];
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

- (void)showFollowers {
    NSLog(@"should be showing followers");
    self.currTab = 1;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        FDPost *selectedPost = (FDPost *)[self.filteredPosts objectAtIndex:indexPath.row];
        [self.delegate performSegueWithIdentifier:@"ShowPostFromNewProfile" sender:selectedPost];
    } else if(indexPath.section == 0) {
        FDPost *selectedPost = (FDPost *)[self.posts objectAtIndex:indexPath.row];
        [self.delegate performSegueWithIdentifier:@"ShowPostFromNewProfile" sender:selectedPost];
    }
}


- (void)showFollowing {
    self.currTab = 2;
    [self.tableView reloadData];
}

- (void)showPosts:(id)sender {
    self.currTab = 0;
    self.canLoadMore = YES;
    [self loadPosts:self.userId];
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

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}


- (void)getFeedForEating {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Eating" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.tableView reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

- (void)getFeedForDrinking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Drinking" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.tableView reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (void)getFeedForMaking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Making" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.tableView reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (void)getFeedForShopping {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Shopping" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.tableView reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

/*-(void) resetCategoryButtons {
    [self.shoppingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor clearColor]];
    [self.makingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor clearColor]];
    [self.eatingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor clearColor]];
    [self.drinkingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor clearColor]];
}*/

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
