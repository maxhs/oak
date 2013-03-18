//
//  FDProfileMapViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDProfileMapViewController.h"
#import "FDPost.h"
#import "AFNetworking.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"
#import "FDPostViewController.h"

@interface FDProfileMapViewController () <MKMapViewDelegate, MKAnnotation, CLLocationManagerDelegate>
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic) BOOL canLoadMore;
@property (nonatomic) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic) AFJSONRequestOperation *morePostsRequestOperation;
@end

@implementation FDProfileMapViewController
@synthesize uid, feedRequestOperation,morePostsRequestOperation, canLoadMore;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSLog(@"nibNameOrNIl: %@",nibNameOrNil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,200,40);
    navTitle.text = @"THE PLACES I'VE BEEN";
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:21];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
    // Shift the title down a bit...
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:-1 forBarMetrics:UIBarMetricsDefault];
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    self.canLoadMore = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self loadPosts:self.uid];
}

-(void)loadPosts:(NSString *)userID{
    self.posts = [NSMutableArray array];
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getMapForProfile:userID success:^(NSMutableArray *newPosts) {
        if (newPosts.count == 0){
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            return;
        }
        for (FDPost *post in newPosts){
            if (post.latitude != 0){
                NSLog(@"post.locationname: %@",post.locationName);
                [self.posts addObject:post];
            }
        }
        self.feedRequestOperation = nil;
        [self showPostsOnMap];
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
    }];
    [self showPostsOnMap];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    self.feedRequestOperation = nil;
}

- (void)showPostsOnMap {
    
    [self.mapView setShowsUserLocation:YES];
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    if (self.posts.count == 0) return;
    NSLog(@"number of posts from show posts on mapview: %d", self.posts.count);
    [self.mapView addAnnotations:self.posts];
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for(id<MKAnnotation> annotation in self.mapView.annotations) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1;
    
    // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1;
    
    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];
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
        [selectButton addTarget:self action:@selector(tappedPostButton:) forControlEvents:UIControlEventTouchUpInside];
        view.rightCalloutAccessoryView = selectButton;
    }
    
    UIButton *selectButton = (UIButton *)view.rightCalloutAccessoryView;
    selectButton.tag = [self.posts indexOfObject:annotation];
    
    return view;
}
        
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    if ([views count] == self.posts.count) {
        NSLog(@"just loaded %d posts",self.posts.count);
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

- (void)tappedPostButton:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ShowPostFromMap" sender:post];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowPostFromMap"]) {
        FDPostViewController *vc = segue.destinationViewController;
        [vc setPostIdentifier:[(FDPost *)sender identifier]];
    }
}


#pragma mark - CLLocationManagerDelegateMethods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"new location: %@",newLocation);
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't find your location!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
