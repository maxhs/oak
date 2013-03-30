//
//  FDAddLocationViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAddLocationViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "FDPost.h"
#import "FDFoursquareAPIClient.h"
#import "FDVenue.h"
#import "FDVenueLocation.h"

@interface FDAddLocationViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *foursquareLogoView;
@property (nonatomic, retain) NSArray *venues;
@property (nonatomic, retain) CLLocationManager *locationManager;
- (IBAction)removeLocation:(id)sender;
@end

@implementation FDAddLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.delegate = self;
    
    //replace ugly background
    for (UIView *view in self.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        self.mapView.frame = CGRectMake(0,0,320,200);
        self.tableContainerView.frame = CGRectMake(0,200,320,304);
    } else {
        
    }
    // there are three possibilities when this view appears:
    
    // 1: the post already has a selected venue
    //
    // in this case, just show the venue as an annotation
    if (FDPost.userPost.venue) {        
        [self.mapView setRegion:MKCoordinateRegionMake(FDPost.userPost.venue.coordinate, MKCoordinateSpanMake(0.0002, 0.0002)) animated:NO];
        [self.mapView addAnnotation:FDPost.userPost.venue];
        [self.mapView selectAnnotation:FDPost.userPost.venue animated:NO];
        
    // 2: the post has a coordinate, but no venue
    //
    // in this case, get venues from foursquare for the post
    } else if (FDPost.userPost.location) {
        [self showVenuesOnMap];
        [self updateVenuesForLocation:FDPost.userPost.location];
        

    // 3: the post doesn't even have coordinates yet
    //
    // in this case, start looking for the gps coordinates
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [self setSearchBar:nil];
    [self setTableView:nil];
    [self setTableContainerView:nil];
    [self setFoursquareLogoView:nil];
    [super viewDidUnload];

}

#pragma mark - Private Methods

- (IBAction)refreshMap:(id)sender {
    self.searchBar.text = nil;
    [[FDFoursquareAPIClient sharedClient] forgetVenues];
    [self.locationManager startUpdatingLocation];
}

- (void)updateVenuesForLocation:(CLLocation *)location {
    
    // if the cached venues are from the same location, just use them
    CLLocation *lastLocation = [[FDFoursquareAPIClient sharedClient] lastLocation];
    CGFloat comparisonThreshold = 0.001;
    
    if (fabsf(location.coordinate.latitude - lastLocation.coordinate.latitude) < comparisonThreshold
        && fabsf(location.coordinate.longitude - lastLocation.coordinate.longitude) < comparisonThreshold) {
        self.venues = [[FDFoursquareAPIClient sharedClient] venues];
        [self showVenuesOnMap];
        [self.tableView reloadData];
    } else {
    
    // otherwise, request new ones
    [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:^(NSArray *results) {
        self.venues = results;
        [self showVenuesOnMap];
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect to Foursquare!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
        
    }
}

- (void)showVenuesOnMap {
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView setShowsUserLocation:YES];
    
    if (self.venues.count == 0) return;
    
    [self.mapView addAnnotations:self.venues];
    
    float minLon = 10000;
    float minLat = 10000;
    float maxLon = -1000;
    float maxLat = -1000;
    
    for (FDVenue *venue in self.venues) {
        minLon = MIN(minLon, venue.coordinate.longitude);
        minLat = MIN(minLat, venue.coordinate.latitude);
        maxLat = MAX(maxLat, venue.coordinate.latitude);
        maxLon = MAX(maxLon, venue.coordinate.longitude);
    }
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(minLat + (maxLat - minLat)/2.0, minLon + (maxLon - minLon)/2.0);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(maxLat-minLat, maxLon-minLon));
    [self.mapView setRegion:region animated:YES];
}

- (void)tappedVenueButton:(UIButton *)button {
    FDVenue *venue = [self.venues objectAtIndex:button.tag];
    [self selectVenue:venue];
}

- (void)selectVenue:(FDVenue *)venue {
    //[FDPost.userPost setVenue:venue];
    FDPost.userPost.locationName = venue.name;
    FDPost.userPost.FDVenueId = venue.FDVenueId;
    FDPost.userPost.address = venue.location.address;
    FDPost.userPost.location = [[CLLocation alloc] initWithLatitude:venue.coordinate.latitude longitude:venue.coordinate.longitude];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectCustomLocationWithName:(NSString *)name {
    FDPost.userPost.locationName = name;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)removeLocation:(id)sender {
    if (FDPost.userPost.venue != nil){
        FDPost.userPost.venue = nil;
    }
    if (FDPost.userPost.locationName != nil){
        FDPost.userPost.locationName = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CLLocationManagerDelegateMethods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self updateVenuesForLocation:locations.lastObject];
    FDPost.userPost.location = locations.lastObject;
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't find your location!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UISearchbarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [TestFlight passCheckpoint:@"Add Location checkpoint"];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    for (id subview in searchBar.subviews) {
        if ([subview respondsToSelector:@selector(setTitle:)]) {
            [subview setTitle:@"MAP"];
        }
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.foursquareLogoView.alpha = 0.0;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            self.tableContainerView.frame = CGRectMake(0, 0, 320, 548);
        } else {
            self.tableContainerView.frame = CGRectMake(0, 0, 320, 460);
        }
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [UIView animateWithDuration:0.25 animations:^{
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            self.tableContainerView.frame = CGRectMake(0, 200, 320, 304);
            self.mapView.frame = CGRectMake(0,0,320,200);
        } else {
            self.tableContainerView.frame = CGRectMake(0, 180, 320, 280);
        }
    }];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:FDPost.userPost.location withQuery:searchBar.text success:^(NSArray *venues) {
        self.venues = venues;
        [self.tableView reloadData];
        [self.tableView setContentOffset:CGPointZero animated:YES];
        [self showVenuesOnMap];
    } failure:^(NSError *error) {
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

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"FoodiaPin"];
    if (view == nil) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FoodiaPin"];
        //[view setImage:[UIImage imageNamed:@"foodiaPin.png"]];
        view.canShowCallout = YES;
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [selectButton addTarget:self action:@selector(tappedVenueButton:) forControlEvents:UIControlEventTouchUpInside];
        view.rightCalloutAccessoryView = selectButton;
    }
    
    UIButton *selectButton = (UIButton *)view.rightCalloutAccessoryView;
    selectButton.tag = [self.venues indexOfObject:annotation];
    
    return view;
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchBar.text.length) return self.venues.count + 1;
    else return self.venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < self.venues.count) {
        FDVenue *venue = [self.venues objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
        cell.textLabel.text = venue.name;
        cell.detailTextLabel.text = venue.location.locality;
        return cell;
    } else {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"AddLocationCell"];
        cell.textLabel.text = [NSString stringWithFormat:@"Use \"%@\" as your location", self.searchBar.text];
        return cell;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.venues.count) {
        FDVenue *venue = [self.venues objectAtIndex:indexPath.row];
        [self selectVenue:venue];
    } else {
        [self selectCustomLocationWithName:self.searchBar.text];
    }
}


@end
