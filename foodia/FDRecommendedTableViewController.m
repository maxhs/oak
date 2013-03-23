//
//  FDRecommendedTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecommendedTableViewController.h"
#import "FDCache.h"
#import "FDAPIClient.h"
#import "FDPostCell.h"
#import "Utilities.h"
#import "FDPlaceViewController.h"
#import "Flurry.h"

@interface FDRecommendedTableViewController ()

@end

@implementation FDRecommendedTableViewController

@synthesize shouldShowLikes = _shouldShowLikes;

- (void)viewDidLoad {
    [super viewDidLoad];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logPageView];
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];*/
    
    //replace ugly background
    for (UIView *view in self.searchDisplayController.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refresh];
}
/*- (void)loadFromCache {
    NSMutableArray *cachedPosts = [FDCache getCachedRecommendedPosts];
    if (cachedPosts == nil)
        [self refresh];
    else {
        self.posts = cachedPosts;
        [self.tableView reloadData];
        if ([FDCache isRecommendedPostCacheStale])
        [self refresh];
    }
}

- (void)saveCache {
    [FDCache cacheRecommendedPosts:self.posts];
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if (indexPath.section == 1 && self.posts.count != 0) {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        }
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
    
        [cell configureForPost:post];
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = cell.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
        cell.locationButton.tag = indexPath.row;
        
        [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        //capture recommend touch event
        UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recButton setFrame:CGRectMake(276,52,60,34)];
        [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        [recButton setTitle:@"Rec" forState:UIControlStateNormal];
        [recButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        recButton.layer.borderWidth = 1.0f;
        recButton.backgroundColor = [UIColor whiteColor];
        recButton.layer.cornerRadius = 17.0f;
        [recButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        recButton.tag = indexPath.row;
        [cell.scrollView addSubview:recButton];
        
        //capture post detail view touch event
        cell.detailPhotoButton.tag = indexPath.row;
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        //capture add comment touch event, send user to post detail view
        UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commentButton setFrame:CGRectMake(382,52,118,34)];
        commentButton.tag = indexPath.row;;
        [commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        [commentButton setTitle:@"Add a comment..." forState:UIControlStateNormal];
        [commentButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        commentButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        commentButton.layer.borderWidth = 1.0f;
        commentButton.backgroundColor = [UIColor whiteColor];
        commentButton.layer.cornerRadius = 17.0f;
        [commentButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [commentButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        
        [cell.scrollView addSubview:commentButton];
    
        if (cell.scrollView.contentOffset.x != 0) [cell.scrollView setContentOffset:CGPointMake(0,0) animated:NO];
    
        return cell;
    //}
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

-(void)showPlace: (id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    [self.delegate performSegueWithIdentifier:@"ShowPlace" sender:(FDPost*)[self.posts objectAtIndex:button.tag]];
}

- (void)refresh {
    // if we already have some posts in the feed, get the feed since the last post
    /*if (self.posts.count && self.shouldShowLikes) {
            NSLog(@"should be showing likes instead");
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getLikedPosts:^(NSMutableArray *posts) {
                self.posts = [[posts arrayByAddingObjectsFromArray:self.posts] mutableCopy];
                NSLog(@"liked posts from rec vc: %@",self.posts);
                NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:posts.count];
                for (FDPost *post in posts) {
                    NSLog(@"each post identifier: %@",post.identifier);
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                    [indexPathsForAddedPosts addObject:path];
                }
                [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                
                [self reloadData];
                self.feedRequestOperation = nil;
                
            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];
            }];
    } else if (self.posts.count && !self.shouldShowLikes) {
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getRecommendedPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *posts) {
                self.posts = [[posts arrayByAddingObjectsFromArray:self.posts] mutableCopy];
                NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:posts.count];
                for (FDPost *post in posts) {
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                    [indexPathsForAddedPosts addObject:path];
                }
                [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                
                [self reloadData];
                self.feedRequestOperation = nil;
                
            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];            
            }];
            // otherwise, get the intial feed
    } else */
    if (self.shouldShowLikes) {
        [Flurry logEvent:@"Loading initial likes" timed:YES];
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getLikedPosts:^(NSMutableArray *posts) {
            NSLog(@"should show likes result: %@",posts);
            if (posts.count == 0){
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
                return;
            }
            self.posts = posts;
            [self reloadData];
            self.feedRequestOperation = nil;
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];
    } else {
        [Flurry logEvent:@"Loading initial recommended posts" timed:YES];
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getRecommendedPostsSuccess:^(NSMutableArray *posts) {
            if (posts.count == 0){
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
                return;
            }
            self.posts = posts;
            [self reloadData];
            self.feedRequestOperation = nil;
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];
    }
}

- (void)loadAdditionalPosts {
    if (self.shouldShowLikes) {
        [Flurry logEvent:@"Loading additional likes" timed:YES];
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getLikedPostsBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
            if (posts.count == 0) {
                self.canLoadAdditionalPosts = NO;
            } else {
                [self.posts addObjectsFromArray:posts];
                NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:posts.count];
                for (FDPost *post in posts) {
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                    [indexPathsForAddedPosts addObject:path];
                }
                [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self reloadData];
            }
            self.feedRequestOperation = nil;
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];

    } else {
        [Flurry logEvent:@"Loading additional recommended posts" timed:YES];
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getRecommendedPostsBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
            if (posts.count == 0) {
                self.canLoadAdditionalPosts = NO;
            } else {
                [self.posts addObjectsFromArray:posts];
                NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:posts.count];
                for (FDPost *post in posts) {
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                    [indexPathsForAddedPosts addObject:path];
                }
                [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self reloadData];
            }
            self.feedRequestOperation = nil;
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];
    }
}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) {
        [self loadAdditionalPosts];
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
        
        //[likerButton setTag: [[liker objectForKey:@"facebook_id"] integerValue]];
        [likerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
        [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[liker objectForKey:@"facebook_id"]]];
        //[likerView setUserId:[liker objectForKey:@"facebook_id"]];
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

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 155;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.posts.count;
}




@end
