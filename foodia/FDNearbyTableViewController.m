//
//  FDNearbyTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 8/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDNearbyTableViewController.h"
#import "FDCache.h"
#import "FDPostNearbyCell.h"
#import "FDMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FDFeedViewController.h"
#import "FDGoogleAPIClient.h"

@interface FDNearbyTableViewController () <CLLocationManagerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate>
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, strong) UISearchBar *locationSearchBar;
@property (nonatomic, strong) UISearchBar *foodSearchBar;
@property (nonatomic, strong) UISearchDisplayController *locationSearch;
@property (nonatomic, strong) UISearchDisplayController *foodSearch;
@property (nonatomic, retain) NSArray *locations;
//@property (nonatomic, retain) NSMutableArray *filteredLocations;
@end

@implementation FDNearbyTableViewController
@synthesize locations;

- (void)viewDidLoad {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [TestFlight passCheckpoint:@"Viewing Nearby View"];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateSearch) name:@"ActivateSearch" object:nil];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    //visual setup
    self.locationSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y-44,320,44)];
    //self.foodSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,44,320,44)];
    //set custom font in searchBar
    for(UIView *subView in self.locationSearchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        }
    }
    self.locationSearch = [[UISearchDisplayController alloc] initWithSearchBar:self.locationSearchBar contentsController:self];
    //self.foodSearch = [[UISearchDisplayController alloc] initWithSearchBar:self.foodSearchBar contentsController:self];
    FDFeedViewController *vc = (FDFeedViewController *)self.parentViewController;
    NSLog(@"vc: %@", vc);
    
    self.locationSearch.searchResultsDataSource = self;
    self.locationSearch.searchResultsDelegate = self;
    self.locationSearch.delegate = self;
    self.locationSearchBar.delegate = self;
    self.locationSearchBar.placeholder = @"City, State, ZIP or Country";
    self.tableView.tableHeaderView = self.locationSearchBar;
    
    //self.locations = [NSArray arrayWithObjects:@"San Francisco", @"Oakland", @"New York City",nil];
    //self.filteredLocations = [NSMutableArray arrayWithObjects:nil];
    
    for (UIView *view in self.locationSearchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

/*- (void)loadFromCache {
    
    NSMutableArray *cachedPosts = [FDCache getCachedNearbyPosts];
    if (cachedPosts == nil)
        [self refresh];
    else {
        self.posts = cachedPosts;
        [self.tableView reloadData];
        if ([FDCache isNearbyPostsCacheStale])
            [self refresh];
    }
}*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.locationSearch.searchResultsTableView) return 2;
    else if (section == 1) return self.posts.count;
    else return 0;
}
- (void)saveCache {
}

- (void)refresh {
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Merde!" message:@"Couldn't find your location. Refresh to try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [manager stopUpdatingLocation];
    [self requestPostsNearLocation:newLocation];
    [[FDGoogleAPIClient sharedClient] getVenuesNearLocation:newLocation success:^(NSArray *results){
        NSLog(@"google results from nearby controller: %@",results);
    }failure:^(NSError *error){
        NSLog(@"error: %@", error.description);
    }];
    [self reloadData];
}

- (void)requestPostsNearLocation:(CLLocation *)location {
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getPostsNearLocation:location success:^(NSMutableArray * posts) {
        self.posts = posts;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.posts.count == 0) {
            UIView *noResultsView = [[UIView alloc] initWithFrame:CGRectMake(10,132,300,176)];
            UILabel *noResults = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,176)];
            noResultsView.tag = 123455;
            noResults.text = @"Sorry, but we couldn't find any results. Please try again with a different location. \n ... \n Or pull down to return your Current Location.";
            noResults.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:18];
            noResults.textColor = [UIColor lightGrayColor];
            noResults.numberOfLines = 5;
            [noResults setBackgroundColor:[UIColor clearColor]];
            noResults.textAlignment = UITextAlignmentCenter;
            self.tableView.separatorColor = [UIColor clearColor];
            [noResultsView addSubview:noResults];
            [self.tableView addSubview:noResultsView];
            
        } else {
            UIView *noResultsView = [self.view viewWithTag:123455];
            [noResultsView removeFromSuperview];
        }
        [self reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self reloadData];
    }];
    //[(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"posts.count: %u", self.posts.count);
    if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 0) {
        static NSString *currentLocation = @"currentLocation";
        UITableViewCell *current = [tableView dequeueReusableCellWithIdentifier:currentLocation];
        if (current == nil) {
            current = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:currentLocation];
            current.textLabel.text = @"Current Location";
            current.selectionStyle = UITableViewCellSelectionStyleGray;
            [current.textLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:18]];
            [current.textLabel setTextColor:[UIColor blueColor]];
        }
        
        return current;

    } else if (tableView == self.locationSearch.searchResultsTableView) {
        UITableViewCell *addSearchLocation = [self.locationSearch.searchResultsTableView dequeueReusableCellWithIdentifier:@"addSearchLocation"];
        
        if (addSearchLocation == nil) {
            addSearchLocation = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addSearchLocation"];
            [addSearchLocation.textLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:18]];
            [addSearchLocation.textLabel setTextColor:[UIColor darkGrayColor]];
            addSearchLocation.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        addSearchLocation.textLabel.text = [NSMutableString stringWithFormat:@"Search for: \"%@\"",self.locationSearchBar.text];
        return addSearchLocation;
    } else {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostNearbyCell *cell = (FDPostNearbyCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostNearbyCell" owner:self options:nil];
            cell = (FDPostNearbyCell *)[nib objectAtIndex:0];
        }
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = cell.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        UIButton *mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [mapButton setFrame:CGRectMake(126,5,143,115)];
        [mapButton addTarget:self action:@selector(selectMap:) forControlEvents:UIControlEventTouchUpInside];
        mapButton.tag = indexPath.row;
        [cell addSubview:mapButton];
    
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return cell;
    }
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.locationSearch.searchResultsTableView) return 1;
    else return 2;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.locationSearch.searchResultsTableView) return 44;
    else return 155;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView != self.locationSearch.searchResultsTableView && indexPath.section == 1) {
        if ([self.delegate respondsToSelector:@selector(postTableViewController:didSelectPost:)]) {
            [self.delegate postTableViewController:self didSelectPost:[self.posts objectAtIndex:indexPath.row]];
        }
    } else if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 0){
        [self.locationSearch setActive:NO animated:YES];
        [self.locationManager startUpdatingLocation];
        [self resignFirstResponder];
    } else if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 1){
        [self findNewLocation:self.locationSearchBar.text];
        [self resignFirstResponder];
    }
}

- (void) findNewLocation:(NSString *)newLocationText {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    CLGeocoder *newGeo = [[CLGeocoder alloc] init];
    [newGeo geocodeAddressString:newLocationText completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            NSLog(@"no error. here are those placemarks: %@", [placemarks objectAtIndex:0]);
            CLPlacemark *newLocation = [placemarks objectAtIndex:0];
            [self requestPostsNearLocation:newLocation.location];
            [self.locationSearch setActive:NO animated:YES];
        } else {
            NSLog(@"error: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we couldn't recognize that location. Please try typing it again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        self.posts = nil;
        }
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }];
}
/*- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
 
     //Update the filtered array based on the search text and scope.
 
    [self.filteredLocations removeAllObjects]; // First clear the filtered array.
    
    // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    for (NSString *locationName in self.locations)
    {
        //if (result == NSOrderedSame)
        //{
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:locationName]) {
            [self.filteredLocations addObject:locationName];
        }
        //}
        //NSLog(@"filteredLocations:%@",self.filteredLocations);
    }
    
}*/


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            [self.tableView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
        } else {
            [self.tableView setFrame:CGRectMake(0,-24,320,self.view.bounds.size.height)];
        }  
    }];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{[self.tableView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
    }];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    //[self filterContentForSearchText:searchString scope:
     //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
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

- (void)activateSearch {
    [self.locationSearchBar setFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y,320,44)];
}


@end
