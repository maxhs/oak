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
#import "FDUser.h"
#import "UIButton+WebCache.h"
#import "FDCache.h"
#import <iAd/ADBannerView.h>

#define METERS_TO_FEET  3.2808399
#define METERS_TO_MILES 0.000621371192
#define METERS_CUTOFF   1000
#define FEET_CUTOFF     3281
#define FEET_IN_MILES   5280

@interface FDRecommendedTableViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, ADBannerViewDelegate>
@property BOOL editMode;
@property (strong, nonatomic) UIView *editContainerView;
@property (strong, nonatomic) UIButton *sortByDistanceButton;
@property (strong, nonatomic) UIButton *sortByPopularityButton;
@property (strong, nonatomic) UIButton *rankButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (weak, nonatomic) AFJSONRequestOperation *holdRequestOperation;
@property BOOL showingDistance;
@property BOOL showingRank;

@property (nonatomic, retain) ADBannerView *adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
@end

@implementation FDRecommendedTableViewController

@synthesize holdRequestOperation;
@synthesize shouldShowKeepers = _shouldShowKeepers;
@synthesize editMode = _editMode;
@synthesize editContainerView;
@synthesize locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize showingDistance = _showingDistance;
@synthesize showingRank = _showingRank;
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;

- (void)viewDidLoad {
    [super viewDidLoad];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logPageView];
    [self.refreshHeaderView setHidden:YES];
    
    //location manager stuff
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    //set up editcontainer stuff
    self.editContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,-44,320,44)];
    [self.editContainerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"newFoodiaHeader"]]];
    
    self.sortByDistanceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sortByDistanceButton setFrame:CGRectMake(222, 7, 88, 34)];
    [self.sortByDistanceButton setTitle:@"DISTANCE" forState:UIControlStateNormal];
    [self.sortByDistanceButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.sortByDistanceButton.layer.cornerRadius = 17.0;
    self.sortByDistanceButton.clipsToBounds = YES;
    [self.editContainerView addSubview:self.sortByDistanceButton];

    
    self.rankButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rankButton setFrame:CGRectMake(116, 7, 88, 34)];
    [self.rankButton setTitle:@"MY RANK" forState:UIControlStateNormal];
    [self.rankButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.rankButton.layer.cornerRadius = 17.0;
    self.rankButton.clipsToBounds = YES;
    [self.rankButton setHidden:YES];
    [self.editContainerView addSubview:self.rankButton];
    
    self.sortByPopularityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sortByPopularityButton setTitle:@"POPULAR" forState:UIControlStateNormal];
    [self.sortByPopularityButton setFrame:CGRectMake(10, 7, 88, 34)];
    [self.sortByPopularityButton.titleLabel setTextColor:[UIColor darkGrayColor]];
    self.sortByPopularityButton.layer.cornerRadius = 17.0;
    self.sortByPopularityButton.clipsToBounds = YES;
    [self.editContainerView addSubview:self.sortByPopularityButton];
    
    self.tableView.tableHeaderView = self.editContainerView;
    
    //conditionals to support the button actions depending on whether its the recommended view or the keepers view
    if (_shouldShowKeepers){
        [self.sortByDistanceButton addTarget:self action:@selector(sortByDistance:) forControlEvents:UIControlEventTouchUpInside];
        [self.rankButton addTarget:self action:@selector(rank) forControlEvents:UIControlEventTouchUpInside];
        [self.sortByPopularityButton addTarget:self action:@selector(sortByPopularity:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.sortByDistanceButton addTarget:self action:@selector(sortRecByDistance) forControlEvents:UIControlEventTouchUpInside];
        [self.sortByPopularityButton addTarget:self action:@selector(sortRecByPopularity) forControlEvents:UIControlEventTouchUpInside];
    }
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [self.sortByPopularityButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
        [self.rankButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
        [self.sortByDistanceButton.titleLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
    } else {
        [self.sortByPopularityButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.rankButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        [self.sortByDistanceButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
    }

    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];
    
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
    self.navigationItem.rightBarButtonItem = searchBarButton;*/
}

//- (void) activateSearch {
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.showingDistance = NO;
    [UIView animateWithDuration:.25 animations:^{
        [self.editContainerView setAlpha:1.0];
    }];

    /*if (self.shouldShowKeepers){
        //[self loadFromCache];
    } else {
        [self refresh:NO andDistance:nil];
    }*/
}

- (void) refresh {
    [self refresh:NO andDistance:nil];
}

- (void)sortRecByDistance {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.showingRank = NO;
    self.showingDistance = YES;
    [self resetButtonColors];
    [self.sortByDistanceButton setBackgroundColor:kColorLightBlack];
    [self.sortByDistanceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self refresh:NO andDistance:self.currentLocation];
}

- (void)sortRecByPopularity {
    NSLog(@"should be sorting by popualrity");
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.showingRank = NO;
    self.showingDistance = NO;
    [self resetButtonColors];
    [self.sortByPopularityButton setBackgroundColor:kColorLightBlack];
    [self.sortByPopularityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self refresh:YES andDistance:nil];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error: %@",error.description);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([[locations lastObject] horizontalAccuracy] < 0) return;
    self.currentLocation = [locations lastObject];
    [self.locationManager stopUpdatingLocation];
}

- (void)loadFromCache {
    //self.posts = [FDCache getCachedRankedPosts];
    [self.posts removeAllObjects];
    if (self.posts.count != 0){
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        self.holdRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getHeldPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *keepers) {
            NSLog(@"rankedResult: %@",keepers);
            if (keepers.count != self.posts.count){
                self.posts = [[keepers arrayByAddingObjectsFromArray:self.posts] mutableCopy];
                NSLog(@"self.posts count after: %d", self.posts.count);
                /*NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:rankedResult.count];
                for (FDPost *post in rankedResult) {
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                    [indexPathsForAddedPosts addObject:path];
                }
                [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                      withRowAnimation:UITableViewRowAnimationAutomatic];*/
                self.showingRank = YES;
            }
            [self reloadData];
            [FDCache clearCache];
            self.feedRequestOperation = nil;
        
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
        }];
    } else {
        NSLog(@"getting fresh cache");
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
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            [cell.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
        } else {
            [cell.textLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
        }

        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        cell.textLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (self.shouldShowKeepers){
            [cell.textLabel setText:@"Tap and hold any post photo to KEEP it on this list."];
        } else {
            [cell.textLabel setText:@"Follow and be followed.\nSmile at posts and make RECOMMENDATIONS.\n\nSoon enough, they'll be made for you."];
        }
        
        return cell;
    } else {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        }
        FDPost *post;
        if (self.showingRank ==  YES) {
            post = [self.posts objectAtIndex:indexPath.row];
            [self.slidingViewController.panGesture setEnabled:NO];
            [cell.cellMotionButton setHidden:YES];
            [cell configureForPost:post];
            
            /*UIImageView *editingAccessory = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage"]];
            cell.accessoryView = editingAccessory;*/
        } else {
            post = [self.posts objectAtIndex:indexPath.row];
            
            [cell.cellMotionButton setHidden:NO];
            [self.slidingViewController.panGesture setEnabled:YES];
            cell.accessoryView = nil;
            
            [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            cell.likeButton.tag = indexPath.row;
            cell.posterButton.titleLabel.text = post.user.userId;
            [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            
            [self showLikers:cell forPost:post];
            [cell bringSubviewToFront:cell.likersScrollView];
            
            //change the recommend touch event to removeHeldPost
            if (self.shouldShowKeepers){
                [cell.recButton addTarget:self action:@selector(removeHeldPost:) forControlEvents:UIControlEventTouchUpInside];
                [cell.recButton setTag:[post.identifier integerValue]];
                [cell.recButton setTitle:@"Remove" forState:UIControlStateNormal];
                [cell.recCountLabel setHidden:YES];
            } else {
                [cell.recButton addTarget:self action:@selector(removeRecPost:) forControlEvents:UIControlEventTouchUpInside];
                [cell.recButton setTag:[post.identifier integerValue]];
                [cell.recButton setTitle:@"Remove" forState:UIControlStateNormal];
                [cell.recCountLabel setHidden:YES];
            }
            
            //capture post detail view touch event
            cell.detailPhotoButton.tag = indexPath.row;
            [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
            
            //capture add comment touch event, send user to post detail view
            cell.commentButton.tag = indexPath.row;;
            [cell.commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
            
            [cell configureForPost:post];
            
            if (_showingDistance){
                CLLocationDistance distance = [self.currentLocation distanceFromLocation:post.location];
                [cell.timeLabel setText:[NSString stringWithFormat:@"%@",[self stringWithDistance:distance]]];
            }
        }
        
        [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
        cell.locationButton.tag = indexPath.row;
        
        //swipe cell accordingly
        if ([self.swipedCells indexOfObject:post.identifier] != NSNotFound){
            [cell.scrollView setContentOffset:CGPointMake(271,0)];
        } else [cell.scrollView setContentOffset:CGPointZero];
    
        return cell;
    }
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
        //show ad!
        if (!self.shouldShowKeepers) [self createAdBannerView];
    }
}

-(void)showPlace: (id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    [self.delegate performSegueWithIdentifier:@"ShowPlace" sender:(FDPost*)[self.posts objectAtIndex:button.tag]];
}

- (void)endEditMode {
    [self.rankButton setTitle:@"MY RANK" forState:UIControlStateNormal];
    [self.tableView setEditing:NO animated:YES];
    [self saveCache];
    [self.rankButton addTarget:self action:@selector(rank) forControlEvents:UIControlEventTouchUpInside];
}

- (void)resetButtonColors {
    [self.tableView setEditing:NO animated:YES];
    [UIView animateWithDuration:.2 animations:^{
        [self.sortByPopularityButton setBackgroundColor:[UIColor clearColor]];
        [self.sortByDistanceButton setBackgroundColor:[UIColor clearColor]];
        [self.rankButton setBackgroundColor:[UIColor clearColor]];
        [self.sortByPopularityButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.sortByDistanceButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.rankButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
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

- (void)refresh:(BOOL)popularity andDistance:(CLLocation*)location {
    [self resetButtonColors];
    /*if (_showingRank){
        [self loadFromCache];
    } else {*/
        if (!self.shouldShowKeepers){
            [Flurry logEvent:@"Loading initial recommended posts" timed:YES];
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getRecommendedPostsByPopularity:popularity distance:location Success:^(NSMutableArray *posts) {
                if (posts.count == 0){
                    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
                    return;
                } else {
                    [self.posts removeAllObjects];
                    self.posts = posts;
                    [self reloadData];
                    self.feedRequestOperation = nil;
                }
            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];
            }];
        }
    //}
}

- (void)removeHeldPost:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton*)sender;
    [[FDAPIClient sharedClient] removeHeldPost:[NSString stringWithFormat:@"%i",button.tag] success:^(NSArray *result) {
        self.posts = [result mutableCopy];
        [self reloadData];
    } failure:^(NSError *error) {
        
    }];
}

- (void)removeRecPost:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton*)sender;
    [[FDAPIClient sharedClient] removeRecPost:[NSString stringWithFormat:@"%i",button.tag] success:^(NSArray *result) {
        [self refresh:NO andDistance:nil];
    } failure:^(NSError *error) {
        
    }];
}
- (void)sortByPopularity:(id)sender {
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
        NSLog(@"Error sorting keepers by popularity: %@",error.description);
        self.holdRequestOperation = nil;
    }];
}

- (void)rank {
    //[self loadFromCache];
    self.showingDistance = NO;
    self.showingRank = YES;
    [self resetButtonColors];
    [self.tableView setEditing:YES animated:NO];
    [self.rankButton setBackgroundColor:kColorLightBlack];
    [self.rankButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.rankButton setTitle:@"SAVE" forState:UIControlStateNormal];
    [self.rankButton addTarget:self action:@selector(endEditMode) forControlEvents:UIControlEventTouchUpInside];
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
        NSLog(@"Error sorting keepers by distance: %@",error.description);
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
        if ([viewer objectForKey:@"id"] != [NSNull null]) {
            UIImageView *face = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light_smile"]];

            UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [viewerButton setFrame:CGRectMake(((space+imageSize)*index),0,imageSize, imageSize)];
            
            //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
            viewerButton.titleLabel.text = [[viewer objectForKey:@"id"] stringValue];
            viewerButton.titleLabel.hidden = YES;

            [viewerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
            if ([[viewer objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [viewerButton setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
            } else {
                [viewerButton setImageWithURL:[viewer objectForKey:@"avatar_url"] forState:UIControlStateNormal];
            }
            [viewerButton.imageView setBackgroundColor:[UIColor clearColor]];
            [viewerButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
            viewerButton.imageView.layer.cornerRadius = 17.0;
            viewerButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            viewerButton.imageView.layer.shouldRasterize = YES;
            face.frame = CGRectMake((((space+imageSize)*index)+18),18,20,20);
            [cell.likersScrollView addSubview:viewerButton];
            for (NSDictionary *liker in likers) {
                if ([[liker objectForKey:@"id"] isEqualToNumber:[viewer objectForKey:@"id"]]){
                    [cell.likersScrollView addSubview:face];
                    break;
                }
            }
            
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
    if (self.posts.count == 0) return 1;
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


- (void)createAdBannerView {
    self.adBannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0,self.view.frame.size.height-50,320,50)];
    [self.adBannerView setDelegate:self];
    self.tableView.tableFooterView = self.adBannerView;
}

#pragma mark ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (!_adBannerViewIsVisible) {
        _adBannerViewIsVisible = YES;
        //[self fixupAdView:[UIDevice currentDevice].orientation];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (_adBannerViewIsVisible)
    {
        _adBannerViewIsVisible = NO;
        //[self fixupAdView:[UIDevice currentDevice].orientation];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {

}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
    return YES;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

@end
