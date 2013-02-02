//
//  FDMapViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 11/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDMapViewController.h"
#import "FDPost.h"
#import "Utilities.h"
#import "FDVenueLocation.h"
#import "FDNearbyTableViewController.h"
#import "FDPostTableViewController.h"
#import "MKAnnotationView+WebCache.h"
#import <MapKit/MapKit.h>
#import "FDAPIClient.h"
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import "FDFoursquareAPIClient.h"
#import "FDPostCell.h"


@interface FDMapViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *directionsButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *hours;
@property (weak, nonatomic) IBOutlet UILabel *contact;
@property (weak, nonatomic) IBOutlet UILabel *cityStateCountry;
@property (weak, nonatomic) IBOutlet UILabel *streetAddress;
@property (weak, nonatomic) NSString *category;
@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) AFHTTPRequestOperation *detailRequestOperation;
@property (weak, nonatomic) FDPost *post;
@property (strong, nonatomic) NSMutableArray *posts;
@property (nonatomic, retain) CLLocationManager *locationManager;

@end

@implementation FDMapViewController

@synthesize mapView, place, category, posts;

- (void)initialize {
    NSLog(@"initializing mapvew");
    NSLog(@"self.foursquareid: %@",self.venueId);
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    /*if (self.postIdentifier){
        self.postRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getDetailsForPostWithIdentifier:self.postIdentifier success:^(FDPost *post) {
            self.post = post;
        } failure:^(NSError *error) {
            NSLog(@"ERROR LOADING POST %@", error.description);
        }];
        //[self.postRequestOperation start];
    }*/
    [[FDFoursquareAPIClient sharedClient] getDetailsForPlace:self.venueId success:^(NSDictionary *placeDetails) {
        NSLog(@"placeDetails: %@",placeDetails);
        /*self.place = [self.place setAttributesFromDictionary:placeDetails];
        self.categoryLabel.text = [NSString stringWithFormat: @"%@",[[self.place.categories valueForKey:@"name"] componentsJoinedByString:@", " ]];
        for (id object in self.place.hours){
            if (object != nil) NSLog(@"object in self.place.hours: %@", object);
        }*/
        [self showDetails];
        }failure:^(NSError *error) {
            NSLog(@"error from mapview: %@",error.description);
        }];
    /*[[FDAPIClient sharedClient] getPostsForPlace:self.place success:^(id result){
        if ([(NSMutableArray *)result count]) {
            posts = result;
            [self.postsContainerTableView reloadData];
        }
    }failure:^(NSError *error) {
        self.postsContainerTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        NSLog(@"places error. here's the description: %@",error.description);
    }];*/
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initialize];
	// Do any additional setup after loading the view.
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    [TestFlight passCheckpoint:@"Looking at a Place View"];
    self.directionsButton.layer.cornerRadius = 17.0f;
    self.directionsButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.directionsButton.layer.borderWidth = .5f;
    self.reservationsLink.layer.cornerRadius = 17.0f;
    self.reservationsLink.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.reservationsLink.layer.borderWidth = .5f;
    self.menuLink.layer.cornerRadius = 17.0f;
    self.menuLink.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.menuLink.layer.borderWidth = .5f;
    self.totalCheckinsLabel.layer.cornerRadius = 17.0f;
    self.totalCheckinsLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.totalCheckinsLabel.layer.borderWidth = .5f;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
}

- (void) showDetails {
    [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.post){
        [self.mapView addAnnotation:self.post];
        [self.mapView setRegion:MKCoordinateRegionMake(self.post.location.coordinate, MKCoordinateSpanMake(0.01, 0.01))];
        if (self.post.locationName) self.placeLabel.text = self.post.locationName;
        if (self.post.venue.location.address) self.streetAddress.text = self.post.venue.location.address;
    } else {
        [self.mapView addAnnotation:self.place];
        self.placeLabel.text = self.place.name;
        
        self.streetAddress.text = self.place.location.address;
        self.cityStateCountry.text = [NSString stringWithFormat:@"%@, %@",self.place.location.city, self.place.location.state];
        if (!self.place.reservationsUrl) [self.menuLink setHidden:YES];
        if (!self.place.menuUrl)[self.menuLink setHidden:YES];
        if (self.place.totalCheckins) self.totalCheckinsLabel.text = [NSString stringWithFormat:@"%@",self.place.totalCheckins];
        else [self.totalCheckinsLabel setHidden:YES];
        [self.mapView setRegion:MKCoordinateRegionMake(self.place.coordinate, MKCoordinateSpanMake(0.01, 0.01))];
    }
}

- (IBAction)getDirections:(id)sender {
    //CLLocationCoordinate2D currentLocation = self.locationManager.location;
    // this uses an address for the destination.  can use lat/long, too with %f,%f format
    Class itemClass = [MKMapItem class];
    if (itemClass && [itemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate: self.post.location.coordinate addressDictionary: nil];
        MKMapItem* destination = [[MKMapItem alloc] initWithPlacemark: placemark];
        destination.name = self.post.locationName;
        NSArray* items = [[NSArray alloc] initWithObjects: destination, nil];
        NSDictionary* options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 MKLaunchOptionsDirectionsModeDriving,
                                 MKLaunchOptionsDirectionsModeKey, nil];
        [MKMapItem openMapsWithItems: items launchOptions: options];
        
    } else {
        NSString* address = [NSString stringWithFormat:@"%f, %f", self.post.location.coordinate.latitude, self.post.location.coordinate.longitude];
        NSString* url = [NSString stringWithFormat: @"http://maps.google.com/maps?saddr=%f,%f&daddr=%@",
                         self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude,
                         [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
    }
}

- (IBAction)goToMenu {
    NSLog(@"should be going to menu");
}

- (IBAction)getReservation {
    NSLog(@"should be going to menu");
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSLog(@"self.posts.count: %d",self.posts.count);
    return self.posts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 155;
    else return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        /*if (tableView == self.searchDisplayController.searchResultsTableView) {
            FDPost *post = [self.filteredPosts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
        } else {*/
            FDPost *post = [self.posts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
            cell = [self showLikers:cell forPost:post];
            [cell bringSubviewToFront:cell.likersScrollView];
            if (post.location.coordinate.latitude != 0){
            }
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        //}
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        
        return cell;
        
    } else {
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
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
    
    //[self.delegate performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    //[self.delegate performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
