//
//  FDRecommendedTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecommendedTableViewController.h"
#import "FDCache.h"
#import "Constants.h"
#import "FDAPIClient.h"
#import "FDPostCell.h"
#import "Utilities.h"
#import "FDPlaceViewController.h"
#import "Flurry.h"
#import "FDCache.h"

#define METERS_TO_FEET  3.2808399
#define METERS_TO_MILES 0.000621371192
#define METERS_CUTOFF   1000
#define FEET_CUTOFF     3281
#define FEET_IN_MILES   5280

@interface FDRecommendedTableViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property BOOL editMode;
@property (strong, nonatomic) UIView *editContainerView;
@property (strong, nonatomic) UIButton *sortByDistanceButton;
@property (strong, nonatomic) UIButton *sortByPopularityButton;
@property (strong, nonatomic) UIButton *selfSortButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (weak, nonatomic) AFJSONRequestOperation *holdRequestOperation;
@property BOOL showingDistance;
@property BOOL showingRank;
@end

@implementation FDRecommendedTableViewController

@synthesize holdRequestOperation;
@synthesize shouldShowHeld = _shouldShowHeld;
@synthesize editMode = _editMode;
@synthesize editContainerView;
@synthesize locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize showingDistance = _showingDistance;
@synthesize showingRank = _showingRank;

- (void)viewDidLoad {
    [super viewDidLoad];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logPageView];
    //[self.selfSortButton setBackgroundColor:kColorLightBlack];
    //[self.selfSortButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    [self refresh];
    self.editContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,-44,320,44)];
    [self.editContainerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"newFoodiaHeader"]]];
    [self.editContainerView setAlpha:0.0];
    
    self.sortByDistanceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sortByDistanceButton setFrame:CGRectMake(222, 7, 88, 34)];
    [self.sortByDistanceButton addTarget:self action:@selector(sortByDistance:) forControlEvents:UIControlEventTouchUpInside];
    [self.editContainerView addSubview:self.sortByDistanceButton];
    [self.sortByDistanceButton setTitle:@"DISTANCE" forState:UIControlStateNormal];
    [self.sortByDistanceButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
    [self.sortByDistanceButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.sortByDistanceButton.layer.cornerRadius = 17.0;
    self.sortByDistanceButton.clipsToBounds = YES;
    
    self.selfSortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.selfSortButton setFrame:CGRectMake(116, 7, 88, 34)];
    [self.selfSortButton addTarget:self action:@selector(selfSort:) forControlEvents:UIControlEventTouchUpInside];
    [self.editContainerView addSubview:self.selfSortButton];
    [self.selfSortButton setTitle:@"MY RANK" forState:UIControlStateNormal];
    [self.selfSortButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
    [self.selfSortButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.selfSortButton.layer.cornerRadius = 17.0;
    self.selfSortButton.clipsToBounds = YES;
    
    self.sortByPopularityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sortByPopularityButton addTarget:self action:@selector(sortByPopularity:) forControlEvents:UIControlEventTouchUpInside];
    [self.sortByPopularityButton setTitle:@"POPULAR" forState:UIControlStateNormal];
    [self.sortByPopularityButton setFrame:CGRectMake(10, 7, 88, 34)];
    [self.sortByPopularityButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
    [self.sortByPopularityButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.sortByPopularityButton.layer.cornerRadius = 17.0;
    self.sortByPopularityButton.clipsToBounds = YES;
    [self.editContainerView addSubview:self.sortByPopularityButton];
    if (_shouldShowHeld){
        self.tableView.tableHeaderView = self.editContainerView; 
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    

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
    [self.searchDisplayController.searchBar setFrame:CGRectMake(0,0,320,44)];
    [self.view addSubview:self.searchDisplayController.searchBar];
    
    UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"magnifier"] style:UIBarButtonItemStyleBordered target:self action:@selector(activateSearch)];
    self.navigationItem.rightBarButtonItem = searchBarButton;
}

- (void) activateSearch {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    //[super viewWillAppear:animated];
    [self.tableView setEditing:NO animated:YES];
    self.showingDistance = NO;
    [UIView animateWithDuration:.25 animations:^{
        [self.editContainerView setAlpha:1.0];
    }];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([[locations lastObject] horizontalAccuracy] < 0) return;
    self.currentLocation = [locations lastObject];
    [self.locationManager stopUpdatingLocation];
}
- (void)loadFromCache {
    NSMutableArray *cachedPosts = [FDCache getCachedRankedPosts];
    NSLog(@"self.ranked count: %d", cachedPosts.count);
    NSLog(@"self.posts count: %d", self.posts.count);
    if (self.posts.count != cachedPosts.count && self.posts.count != 0){
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        NSLog(@"count between self.posts and ranked.posts is different and not 0");
        self.holdRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getHeldPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *rankedResult) {
            NSLog(@"rankedResult: %@",rankedResult);
            self.posts = [[rankedResult arrayByAddingObjectsFromArray:cachedPosts] mutableCopy];
            NSLog(@"self.ranked count after: %d", cachedPosts.count);
            NSLog(@"self.posts count after: %d", self.posts.count);
            /*NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:rankedResult.count];
            for (FDPost *post in rankedResult) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                [indexPathsForAddedPosts addObject:path];
            }
            [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                  withRowAnimation:UITableViewRowAnimationAutomatic];*/
            self.showingRank = YES;
            [self reloadData];
            [FDCache clearCache];
            self.feedRequestOperation = nil;
            
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];
    } else {
        NSLog(@"count was the same, so we're using the cache");
        self.posts = cachedPosts;
        [self reloadData];
    }
}

- (void)saveCache {
    NSLog(@"saving the ranked posts");
    [FDCache cacheRankedPosts:self.posts];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.posts.count == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        [cell.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        cell.textLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.textLabel setText:@"Tap and hold any post photo to add it to this list."];
        return cell;
    } else {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        }
        
        if (self.showingRank ==  YES) {
            FDPost *post = [self.posts objectAtIndex:indexPath.row];
            [self.slidingViewController.panGesture setEnabled:NO];
            [cell.cellMotionButton setHidden:YES];
            [cell configureForPost:post];
            
            UIImageView *editingAccessory = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage"]];
            cell.accessoryView = editingAccessory;
        } else {
            FDPost *post = [self.posts objectAtIndex:indexPath.row];
            
            [cell.cellMotionButton setHidden:NO];
            [self.slidingViewController.panGesture setEnabled:YES];
            cell.accessoryView = nil;
            
            [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            cell.likeButton.tag = indexPath.row;
            cell.posterButton.titleLabel.text = cell.userId;
            [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            
            [self showLikers:cell forPost:post];
            [cell bringSubviewToFront:cell.likersScrollView];
            
            //capture recommend touch event
            UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [recButton setFrame:CGRectMake(276,52,60,34)];
            if (self.shouldShowHeld){
                [recButton addTarget:self action:@selector(removeHeldPost:) forControlEvents:UIControlEventTouchUpInside];
                [recButton setTag:[post.identifier integerValue]];
                [recButton setTitle:@"Remove" forState:UIControlStateNormal];
                [cell.recCountLabel setHidden:YES];
            } else {
                [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
                [recButton setTitle:@"Rec" forState:UIControlStateNormal];
                [recButton setTag:indexPath.row];
            }
            
            [recButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
            recButton.layer.borderWidth = 1.0f;
            recButton.backgroundColor = [UIColor whiteColor];
            recButton.layer.cornerRadius = 17.0f;
            [recButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
            [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
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
            [commentButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
            [commentButton.titleLabel setTextColor:[UIColor lightGrayColor]];
            
            [cell.scrollView addSubview:commentButton];
            
            [cell configureForPost:post];
            
            if (_showingDistance){
                CLLocationDistance distance = [self.currentLocation distanceFromLocation:post.location];
                [cell.timeLabel setText:[NSString stringWithFormat:@"%@",[self stringWithDistance:distance]]];
            }
        }
        
        [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
        cell.locationButton.tag = indexPath.row;
        if (cell.scrollView.contentOffset.x != 0) [cell.scrollView setContentOffset:CGPointMake(0,0) animated:NO];
    
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self longPress];
}

-(void)longPress {
    [self.tableView setEditing:YES animated:NO];
}

-(BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(NSIndexPath*)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if( sourceIndexPath.row != proposedDestinationIndexPath.row ) return proposedDestinationIndexPath;
    else return sourceIndexPath;
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

- (void)resetButtonColors {
    [self.tableView setEditing:NO animated:YES];
    [self saveCache];
    [UIView animateWithDuration:.2 animations:^{
        [self.sortByPopularityButton setBackgroundColor:[UIColor clearColor]];
        [self.sortByDistanceButton setBackgroundColor:[UIColor clearColor]];
        [self.selfSortButton setBackgroundColor:[UIColor clearColor]];
        [self.sortByPopularityButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.sortByDistanceButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.selfSortButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }];

}

- (NSString *)stringWithDistance:(double)distance {
    BOOL isMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    NSString *format;
    
    if (isMetric) {
        if (distance < METERS_CUTOFF) {
            format = @"%@ m";
        } else {
            format = @"%@ km";
            distance = distance / 1000;
        }
    } else { // assume Imperial / U.S.
        distance = distance * METERS_TO_FEET;
        if (distance < FEET_CUTOFF) {
            format = @"%@ ft";
        } else {
            format = @"%@ mi";
            distance = distance / FEET_IN_MILES;
        }
    }
    
    return [NSString stringWithFormat:format, [self stringWithDouble:distance]];
}

// Return a string of the number to one decimal place and with commas & periods based on the locale.
- (NSString *)stringWithDouble:(double)value {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:1];
    return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

- (void)refresh {
    NSLog(@"refresh called");
    [self resetButtonColors];
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
    if (_showingRank){
        NSLog(@"shuold be showing rank, so not refreshing");
        [self loadFromCache];
    } else {

        if (self.shouldShowHeld) {
            [Flurry logEvent:@"Loading initial held onto" timed:YES];
            self.holdRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getHeldPosts:^(NSMutableArray *posts) {
                if (posts.count == 0){
                    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
                }
                self.posts = posts;
                [self reloadData];
                self.feedRequestOperation = nil;
            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];
            }];
        } else {
            NSLog(@"should be showing recommended posts");
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
}

- (void)removeHeldPost:(id)sender {
    UIButton *button = (UIButton*)sender;
    [[FDAPIClient sharedClient] removeHeldPost:[NSString stringWithFormat:@"%i",button.tag] success:^(NSArray *result) {
        self.posts = [result mutableCopy];
        [self reloadData];
    } failure:^(NSError *error) {
        
    }];
}

- (void)sortByPopularity:(id)sender {\
    self.showingRank = NO;
    self.showingDistance = NO;
    [self resetButtonColors];
    UIButton *button = (UIButton*)sender;
    [button setBackgroundColor:kColorLightBlack];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.holdRequestOperation = [[FDAPIClient sharedClient] getHeldPostsByPopularity:^(NSArray *result) {
        self.posts = [result mutableCopy];
        [self.tableView reloadData];
        self.holdRequestOperation = nil;
    } failure:^(NSError *error) {
        NSLog(@"error getting sorted by populairty posts");
        self.holdRequestOperation = nil;
    }];
}

- (void)selfSort:(id)sender {
    self.showingDistance = NO;
    self.showingRank = YES;
    [self resetButtonColors];
    [self loadFromCache];
    UIButton *button = (UIButton*)sender;
    [button setBackgroundColor:kColorLightBlack];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)sortByDistance:(id)sender {
    self.showingRank = NO;
    self.showingDistance = YES;
    [self resetButtonColors];
    UIButton *button = (UIButton*)sender;
    [button setBackgroundColor:kColorLightBlack];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.holdRequestOperation = [[FDAPIClient sharedClient] getHeldPostsFromLocation:self.currentLocation success:^(NSArray *result) {
        self.posts = [result mutableCopy];
        [self.tableView reloadData];
        self.holdRequestOperation = nil;
    } failure:^(NSError *error) {
        NSLog(@"error getting posts sorted by distance");
        self.holdRequestOperation = nil;
    }];
}

- (void)loadAdditionalPosts {
    /*if (self.shouldShowHeld) {
        [Flurry logEvent:@"Loading additional held onto posts" timed:YES];
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getHeldPostsBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
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
    }*/
}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) {
        [self loadAdditionalPosts];
    }
}


#pragma mark - Display likers

- (FDPostCell *)showLikers:(FDPostCell *)cell forPost:(FDPost *)post{
    NSDictionary *likers = post.likers;
    NSDictionary *viewers = post.viewers;
    [cell.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.likersScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *viewer in viewers) {
        if ([viewer objectForKey:@"facebook_id"] != [NSNull null]) {
            UIImageView *face = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light_smile"]];
            UIImageView *likerView = [[UIImageView alloc] initWithFrame:CGRectMake(((cell.likersScrollView.frame.origin.x)+((space+imageSize)*index)),(cell.likersScrollView.frame.origin.y), imageSize, imageSize)];
            UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            
            //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
            viewerButton.titleLabel.text = [viewer objectForKey:@"facebook_id"];
            viewerButton.titleLabel.hidden = YES;

            [viewerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
            [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]]];
            likerView.userInteractionEnabled = YES;
            likerView.clipsToBounds = YES;
            likerView.layer.cornerRadius = 5.0;
            likerView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
            face.frame = CGRectMake((((space+imageSize)*index)+18),18,20,20);
            [viewerButton setFrame:likerView.frame];
            face.clipsToBounds = NO;
            [cell.likersScrollView addSubview:likerView];
            for (NSDictionary *liker in likers) {
                if ([[liker objectForKey:@"facebook_id"] isEqualToString:[viewer objectForKey:@"facebook_id"]]){
                    [cell.likersScrollView addSubview:face];
                    break;
                }
            }
            [cell.likersScrollView addSubview:viewerButton];
            index++;
    }
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
    if (self.posts.count == 0 && self.shouldShowHeld) return 1;
    else return self.posts.count;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if(fromIndexPath == toIndexPath) return;

    FDPostCell *cellToMove = [self.posts objectAtIndex:fromIndexPath.row];
    [self.posts removeObjectAtIndex:fromIndexPath.row];
    [self.posts insertObject:cellToMove atIndex:toIndexPath.row];
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

 /* Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }*/



@end
