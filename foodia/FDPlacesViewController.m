//
//  FDPlacesViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/19/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#define METERS_TO_FEET  3.2808399
#define METERS_TO_MILES 0.000621371192
#define METERS_CUTOFF   1000
#define FEET_CUTOFF     3281
#define FEET_IN_MILES   5280

#import "FDPlacesViewController.h"
#import "FDCache.h"
#import "FDPostNearbyCell.h"
#import "FDMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FDFeedViewController.h"
#import "FDGoogleAPIClient.h"
#import "FDFoursquareAPIClient.h"
#import "FDVenue.h"
#import "FDVenueLocation.h"
#import "FDPlacesCell.h"
#import "FDFeedViewController.h"

@interface FDPlacesViewController () <CLLocationManagerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate>
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, strong) UISearchBar *locationSearchBar;
@property (nonatomic, strong) UISearchBar *foodSearchBar;
@property (nonatomic, strong) UISearchDisplayController *locationSearch;
//@property (nonatomic, strong) UISearchDisplayController *foodSearch;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, strong) CLLocation *current;
@property (nonatomic, retain) NSMutableArray *filteredLocations;
@property (nonatomic, retain) FDFeedViewController *parentFeedVC;
@property (weak, nonatomic) IBOutlet UIImageView *foursquareLogoView;

@end

@implementation FDPlacesViewController
@synthesize current;

- (void)viewDidLoad {
    [TestFlight passCheckpoint:@"Viewing Places View"];
    [super viewDidLoad];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateSearch) name:@"ActivateSearch" object:nil];*/
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    self.locations = [NSMutableArray array];
    //visual setup
    self.locationSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y-44,320,44)];
    self.foodSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y-44,320,44)];
    //set custom font in searchBar
    for(UIView *subView in self.locationSearchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14];
        }
    }
    
    //setting the global feedview searchbar delegate to places right now.
    self.parentFeedVC = [[FDFeedViewController alloc] init];
    self.parentFeedVC = (FDFeedViewController*) self.parentViewController;
    
    self.locationSearch = [[UISearchDisplayController alloc] initWithSearchBar:self.locationSearchBar contentsController:self];
    self.locationSearch.searchResultsDataSource = self;
    self.locationSearch.searchResultsDelegate = self;
    self.locationSearch.delegate = self;
    self.locationSearchBar.delegate = self;
    self.locationSearchBar.placeholder = @"Current Location";
    self.tableView.tableHeaderView = self.locationSearchBar;
    
    for (UIView *view in self.locationSearchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    
    self.filteredLocations = [NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
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
    self.current = newLocation;
    
    [self requestPlacesNearLocation:newLocation];
    NSLog(@"new location: %@",newLocation);
    
    /*[[FDGoogleAPIClient sharedClient] getVenuesNearLocation:newLocation success:^(NSArray *results){
        NSLog(@"google results from nearby controller: %@",results);
    }failure:^(NSError *error){
        NSLog(@"error: %@", error.description);
    }];*/
    [self reloadData];
}

- (void)requestPlacesNearLocation:(CLLocation *)location {
    // if the cached venues are from the same location, just use them
    CLLocation *lastLocation = [[FDFoursquareAPIClient sharedClient] lastLocation];
    CGFloat comparisonThreshold = 0.001;
    
    if (fabsf(location.coordinate.latitude - lastLocation.coordinate.latitude) < comparisonThreshold
        && fabsf(location.coordinate.longitude - lastLocation.coordinate.longitude) < comparisonThreshold) {
        self.locations = [NSMutableArray arrayWithArray:[[FDFoursquareAPIClient sharedClient] venues]];
        //[self showVenuesOnMap];
        NSLog(@"using old data");
        [self.tableView reloadData];
    } else {
        NSLog(@"gotta get new data");
        // otherwise, request new ones
        [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:^(NSArray *results) {
            self.locations = [NSMutableArray arrayWithArray:results];
            //[self showVenuesOnMap];
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect to Foursquare!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 0) {
        static NSString *currentLocation = @"currentLocation";
        UITableViewCell *currentCell = [tableView dequeueReusableCellWithIdentifier:currentLocation];
        if (currentCell == nil) {
            currentCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:currentLocation];
            currentCell.textLabel.text = @"Current Location";
            currentCell.selectionStyle = UITableViewCellSelectionStyleGray;
            [currentCell.textLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:18]];
            [currentCell.textLabel setTextColor:[UIColor blueColor]];
        }
        return currentCell;
        
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
        FDPlacesCell *cell = (FDPlacesCell *)[tableView dequeueReusableCellWithIdentifier:@"PlacesCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPlacesCell" owner:self options:nil];
            cell = (FDPlacesCell *)[nib objectAtIndex:0];
        }
        FDVenue *location = [self.locations objectAtIndex:indexPath.row];
        NSLog(@"trying to draw cell for this location: %@",location.name);
        [[FDFoursquareAPIClient sharedClient] getDetailsForPlace:location.FDVenueId success:^(NSDictionary *results){
            NSLog(@"results from API call in vc: %@",results);
            [location setAttributesFromDictionary:results];
            cell.placeName.text = location.name;
            cell.placeAddress.text = location.location.locality;
            cell.likes.text = [NSString stringWithFormat:@"Likes: %@",[location.likes valueForKey:@"count"]];
            cell.statusHours.text = location.statusHours;
            CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
            CLLocationDistance distance = [venueLocation distanceFromLocation:self.current];
            [cell.distance setText:[NSString stringWithFormat:@"%@", [self stringWithDistance:distance]]];
            [[FDAPIClient sharedClient] getPostsForPlace:location success:^(NSMutableArray *result){
                NSLog(@"first result: %@",[result objectAtIndex:0]);
                
                if ([result count]) {
                    FDPost *post = [result objectAtIndex:0];
                    [cell.postImage setImageWithURL:[NSURL URLWithString:post.detailImageUrlString]];
                    NSLog(@"found an image: %@",post.detailImageUrlString);
                } else {
                    NSLog(@"couldn't find a post image at: %@",location.name);
                }
                
            }failure:^(NSError *error) {
                NSLog(@"places error. here's the description: %@",error.description);
            }];
        } failure:^(NSError *error){
            NSLog(@"error.description: %@",error.description);
        }];
        
        /*if (location.hereNow) NSLog(@"hereNow: %@",location.hereNow);
        if (location.totalCheckins) NSLog(@"totalcheckins: %@",location.totalCheckins);
        if (location.menuUrl) NSLog(@"menuurl: %@",location.menuUrl);
        if (location.reservationsUrl) NSLog(@"reservations: %@",location.reservationsUrl);
        if (location.url) NSLog(@"url: %@",location.url);*/
        return cell;
    }
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
    [self.locationManager stopUpdatingLocation];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.locationSearch.searchResultsTableView) return 1;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.locationSearch.searchResultsTableView) return 2;
    else if (section == 0) return self.locations.count;
    else return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) return 44;
    else return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && tableView != self.locationSearch.searchResultsTableView) {
        FDMapViewController *placeVC;
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
            placeVC = [storyboard instantiateViewControllerWithIdentifier:@"PlaceView"];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            placeVC = [storyboard instantiateViewControllerWithIdentifier:@"PlaceView"];
        }
        [placeVC setPlace:[self.locations objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:placeVC animated:YES];
    } else if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 0){
        NSLog(@"find results for current location");
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self.locationSearch setActive:NO animated:YES];
        [self.locationManager startUpdatingLocation];
        [self resignFirstResponder];
    } else if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 1){
        [self findNewLocation:self.locationSearchBar.text];
        NSLog(@"find results for new location: %@",self.locationSearchBar.text);
        [self resignFirstResponder];
    }
}

- (void) findNewLocation:(NSString *)newLocationText {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    CLGeocoder *newGeo = [[CLGeocoder alloc] init];
    [newGeo geocodeAddressString:newLocationText completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            CLPlacemark *newLocation = [placemarks objectAtIndex:0];
            [self requestPlacesNearLocation:newLocation.location];
            [self.locationSearch setActive:NO animated:YES];
        } else {
            NSLog(@"error: %@", error);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we couldn't recognize that location. Please try typing it again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
            self.locations = nil;
        }
    }];
}
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
 
 //Update the filtered array based on the search text and scope.
 
 [self.filteredLocations removeAllObjects]; // First clear the filtered array.
 
 // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
     for (NSString *locationName in self.locations)
     {
         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
         if([predicate evaluateWithObject:locationName]) {
             [self.filteredLocations addObject:locationName];
         }
     }
     NSLog(@"filteredLocations:%@",self.filteredLocations);
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"FoodiaPin"];
    if (view == nil) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FoodiaPin"];
        view.canShowCallout = YES;
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [selectButton addTarget:self action:@selector(tappedVenueButton:) forControlEvents:UIControlEventTouchUpInside];
        view.rightCalloutAccessoryView = selectButton;
    }
    
    UIButton *selectButton = (UIButton *)view.rightCalloutAccessoryView;
    selectButton.tag = [self.locations indexOfObject:annotation];
    
    return view;
}

#pragma mark UISearchDisplayController Delegate Methods

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    //[tableView setHidden:YES];
}

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    //[self.delegate hideSlider];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    // keep the cancel button enabled
    /*for (id subview in controller.searchBar.subviews) {
        if ([subview respondsToSelector:@selector(setEnabled:)]) {
            [subview setEnabled:YES];
        }
    }*/
    
    [self.delegate activateSearch];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            NSLog(@"activating places search");
            [self.tableView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
        } else {
            [self.tableView setFrame:CGRectMake(0,-24,320,self.view.bounds.size.height)];
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:current withQuery:searchBar.text success:^(NSArray *venues) {
        self.locations = [NSMutableArray arrayWithArray:venues];
        NSLog(@"new self.locations after changing search text: %@", self.locations);
        [self reloadData];
        [self.tableView setContentOffset:CGPointZero animated:YES];
        [self.locationSearch setActive:NO animated:YES];
        //[self showVenuesOnMap];
    } failure:^(NSError *error) {
        NSLog(@"theres an error! %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect to Foursquare!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    [searchBar resignFirstResponder];
    
    // keep the cancel button enabled
    for (id subview in searchBar.subviews) {
        if ([subview respondsToSelector:@selector(setEnabled:)]) {
            [subview setEnabled:YES];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.foursquareLogoView.hidden = searchBar.text.length;
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

@end
