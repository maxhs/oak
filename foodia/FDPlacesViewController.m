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
#import "FDPlaceViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FDFeedViewController.h"
#import "FDGoogleAPIClient.h"
#import "FDFoursquareAPIClient.h"
#import "FDVenue.h"
#import "FDVenueLocation.h"
#import "FDPlacesCell.h"
#import "UIImageView+AFNetworking.h"
#import "FDFeedViewController.h"
#import "FoursquareCategory.h"
#import "Flurry.h"

@interface FDPlacesViewController () <CLLocationManagerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate>
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, strong) UISearchBar *locationSearchBar;
@property (nonatomic, strong) UISearchBar *objectSearchBar;
@property (nonatomic, strong) UISearchDisplayController *locationSearch;
@property (nonatomic, strong) UISearchDisplayController *objectSearch;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) CLLocation *current;
@property (nonatomic, retain) NSMutableArray *filteredLocations;
@property (weak, nonatomic) IBOutlet UIImageView *foursquareLogoView;
@property (retain , nonatomic) CLLocation *lastLocation;

@end

@implementation FDPlacesViewController
@synthesize current;
@synthesize lastLocation = _lastLocation;
@synthesize locations = _locations;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;

    [TestFlight passCheckpoint:@"Viewing Places View"];
    [Flurry logPageView];
    self.locations = [NSMutableArray array];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];*/

    //visual setup
    self.locationSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y-44,320,44)];
    self.objectSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x,self.tableView.frame.origin.y-44,320,44)];
    [self.locationSearch.searchResultsTableView addSubview:self.objectSearchBar];
    //set custom font in searchBar
    for(UIView *subView in self.locationSearchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kAvenirMedium size:14];
        }
    }
    
    self.locationSearch = [[UISearchDisplayController alloc] initWithSearchBar:self.locationSearchBar contentsController:self];
    self.locationSearch.searchResultsDataSource = self;
    self.locationSearch.searchResultsDelegate = self;
    self.locationSearch.delegate = self;
    self.objectSearchBar.delegate = self;
    self.locationSearchBar.delegate = self;
    [self.locationSearchBar setTintColor:[UIColor whiteColor]];
    self.locationSearchBar.placeholder = @"Current Location";
    self.tableView.tableHeaderView = self.locationSearchBar;
    for (UIView *view in self.locationSearchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    
}

-(void)viewWillAppear:(BOOL)animated {
    [self refresh];
    [super viewWillAppear:YES];
    self.locationManager.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingLocation];
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
    NSLog(@"testing when refresh is called");
    [self.locationManager startUpdatingLocation];
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Merde!" message:@"Couldn't find your location. Refresh to try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([[locations lastObject] horizontalAccuracy] < 0) return;
    [self requestPlacesNearLocation:locations.lastObject];
    [self.locationManager stopUpdatingLocation];
}

- (void)requestPlacesNearLocation:(CLLocation *)location {
    [Flurry logEvent:@"Requesting places near location" timed:YES];
    self.current = location;
    [self.locations removeAllObjects];
    [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:^(NSArray *venues) {
        for (FDVenue *venue in venues){
            [self.locations addObject:[self loadDetailsForLocation:venue]];
        }
        [self reloadData];
    } failure:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect to Foursquare!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
}

- (FDVenue*) loadDetailsForLocation:(FDVenue*)location {
    [[FDFoursquareAPIClient sharedClient] getDetailsForPlace:location.FDVenueId success:^(NSDictionary *results){
        [location setAttributesFromDictionary:results];
        [[FDAPIClient sharedClient] getPostsForPlace:location success:^(NSMutableArray *result){
            if ([result count]) {
                FDPost *post = (FDPost *)[result objectAtIndex:0];
                [location setImageViewUrl:post.featuredImageUrlString];
            }
        } failure:^(NSError *error){
                NSLog(@"error.description: %@",error.description);
        }];
        //build your list of locations
     }failure:^(NSError *error) {
         NSLog(@"places error. here's the description: %@",error.description);
     }];
    return location;
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
            [currentCell.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
            [currentCell.textLabel setTextColor:[UIColor blueColor]];
        }
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:[UIColor darkGrayColor]];
        currentCell.selectedBackgroundView = cellbg;
        return currentCell;
        
    } else if (tableView == self.locationSearch.searchResultsTableView) {
        UITableViewCell *addSearchLocation = [self.locationSearch.searchResultsTableView dequeueReusableCellWithIdentifier:@"addSearchLocation"];
        if (addSearchLocation == nil) {
            addSearchLocation = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addSearchLocation"];
            [addSearchLocation.textLabel setFont:[UIFont fontWithName:kAvenirMedium size:15]];
            [addSearchLocation.textLabel setTextColor:[UIColor darkGrayColor]];
            addSearchLocation.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        addSearchLocation.textLabel.text = [NSMutableString stringWithFormat:@"Search for: \"%@\"",self.locationSearchBar.text];
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:[UIColor darkGrayColor]];
        addSearchLocation.selectedBackgroundView = cellbg;
        return addSearchLocation;
    } else {
        FDPlacesCell *cell = (FDPlacesCell *)[tableView dequeueReusableCellWithIdentifier:@"PlacesCell"];
        if (cell == nil) cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPlacesCell" owner:self options:nil] lastObject];
        FDVenue *location = [self.locations objectAtIndex:indexPath.row];
        cell.placeName.text = location.name;
        cell.placeAddress.text = location.location.locality;
        cell.likes.text = [NSString stringWithFormat:@"Likes: %@",[location.likes valueForKey:@"count"]];
        cell.statusHours.text = location.statusHours;
        [cell.postImage setImageWithURL:[NSURL URLWithString:location.imageViewUrl] placeholderImage:[UIImage imageNamed:@"icon.png"]];
        cell.postImage.clipsToBounds = YES;
        cell.postImage.layer.cornerRadius = 2.0f;
        CLLocation *venueLocation = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
        CLLocationDistance distance = [venueLocation distanceFromLocation:self.current];
        [cell.distance setText:[NSString stringWithFormat:@"%@", [self stringWithDistance:distance]]];
        /*for (FoursquareCategory *category in location.categories){
            if (category.primary){
                NSLog(@"primary category name: %@",category.name);
                NSLog(@"primary category pluralName: %@",category.pluralName);
                NSLog(@"primary category shortName: %@",category.shortName);
            }
        }*/
        /*if (location.hereNow) NSLog(@"hereNow: %@",location.hereNow);
        if (location.totalCheckins) NSLog(@"totalcheckins: %@",location.totalCheckins);
        if (location.menuUrl) NSLog(@"menuurl: %@",location.menuUrl);
        if (location.reservationsUrl) NSLog(@"reservations: %@",location.reservationsUrl);*/
        UIView *cellbg = [[UIView alloc] init];
        [cellbg setBackgroundColor:[UIColor darkGrayColor]];
        cell.selectedBackgroundView = cellbg;
        return cell;
    }
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [self performSelector:@selector(hideLoadingOverlay) withObject:nil afterDelay:1.0];
    }
}

- (void)hideLoadingOverlay {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
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
    if (tableView == self.locationSearch.searchResultsTableView) return 44;
    else return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if(indexPath.section == 0 && tableView != self.locationSearch.searchResultsTableView) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        FDPlaceViewController *placeVC;
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5" bundle:nil];
            placeVC = [storyboard instantiateViewControllerWithIdentifier:@"PlaceView"];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            placeVC = [storyboard instantiateViewControllerWithIdentifier:@"PlaceView"];
        }
        FDVenue *venue = [self.locations objectAtIndex:indexPath.row];
        [placeVC setVenueId:venue.FDVenueId];
        [self.navigationController pushViewController:placeVC animated:YES];
    } else if (tableView == self.locationSearch.searchResultsTableView && indexPath.row == 0){
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
 
 /*[self.filteredLocations removeAllObjects]; // First clear the filtered array.
 
 // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
     for (NSString *locationName in self.locations)
     {
         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
         if([predicate evaluateWithObject:locationName]) {
             [self.filteredLocations addObject:locationName];
         }
     }
     NSLog(@"filteredLocations:%@",self.filteredLocations);*/
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
    [tableView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.8]];
}

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"will be beginning search now");
    // keep the cancel button enabled
    for (id subview in self.locationSearch.searchBar.subviews) {
        if ([subview respondsToSelector:@selector(setEnabled:)]) {
            [subview setEnabled:YES];
        }
    }
    if (!self.navigationController.navigationBar.isHidden){

        [self.delegate hideSlider];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        //[self.objectSearchBar setHidden:NO];
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        //[self.objectSearchBar setHidden:YES];
    }
    

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

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:searchString completionHandler:^(NSArray *placemarks, NSError *error) {
        self.filteredLocations = [NSMutableArray arrayWithArray:[placemarks mutableCopy]];
        [self.locationSearch.searchResultsTableView reloadData];
    }];
    return NO;
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
