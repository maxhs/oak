//
//  FDPlaceViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 11/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPlaceViewController.h"
#import "FDPost.h"
#import "Utilities.h"
#import "FDVenueLocation.h"
#import "FDNearbyTableViewController.h"
#import "FDPostTableViewController.h"
#import "MKAnnotationView+WebCache.h"
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import "FDAPIClient.h"
#import <CoreLocation/CoreLocation.h>
#import "Facebook.h"
#import <QuartzCore/QuartzCore.h>
#import "FDFoursquareAPIClient.h"
#import "FDPostCell.h"
#import "FDPostViewController.h"
#import "FDCustomSheet.h"
#import "FDRecommendViewController.h"
#import "FDProfileViewController.h"
#import "FDWebViewController.h"

@interface FDPlaceViewController () <CLLocationManagerDelegate, MKMapViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextViewDelegate>
@property (strong, nonatomic) FDVenue *place;
@property (nonatomic, weak) IBOutlet UIButton *directionsButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityStateCountry;
@property (weak, nonatomic) IBOutlet UILabel *streetAddress;
@property (weak, nonatomic) NSString *category;
@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) AFHTTPRequestOperation *detailRequestOperation;
@property (weak, nonatomic) FDPost *post;
@property (strong, nonatomic) NSMutableArray *posts;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UITextView *hoursTextView;
@end

@implementation FDPlaceViewController

@synthesize mapView, category, posts, venueId, postsContainerTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
    //self.hoursTextView.delegate = self;
    [self.postsContainerTableView setDelegate:self];
    [self.postsContainerTableView setDataSource:self];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[FDFoursquareAPIClient sharedClient] getDetailsForPlace:self.venueId success:^(NSDictionary *placeDetails) {
        self.place = [[FDVenue alloc] init];
        self.place = [self.place setAttributesFromDictionary:placeDetails];
        if ([self.place.hours count]){
            NSString *hoursString = @"";
            for (int i = 0; i < [self.place.hours count]; i++){
                id object = [self.place.hours objectAtIndex:i];
                if (object != nil) {
                    NSString *renderedTime;
                    for (NSDictionary *timeDict in [object valueForKeyPath:@"open"]){
                        renderedTime = [timeDict valueForKey:@"renderedTime"];
                    }
                    hoursString = [NSString stringWithFormat:@"%@%@: %@\n",hoursString,[object valueForKey:@"days"], renderedTime];
                }
            }
            [self.hoursTextView setText:hoursString];
            [self.hoursTextView setFrame:CGRectMake(-4,-8,160,self.hoursTextView.contentSize.height-20)];
        } else {
            [self.hoursTextView setText:@"(Hours unavailable)"];
            [self.hoursTextView setTextColor:[UIColor lightGrayColor]];
            [self.hoursTextView setFrame:CGRectMake(4,-8,160,self.hoursTextView.contentSize.height)];
        }
        NSLog(@"self.place.venueid: %@",self.place.FDVenueId);
        [[FDAPIClient sharedClient] getPostsForPlace:self.place success:^(id result){
            if ([(NSMutableArray *)result count]) {
                self.posts = result;
                [self.postsContainerTableView reloadData];
                [self showDetails];
            } else {
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            }
        }failure:^(NSError *error) {
            self.postsContainerTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            NSLog(@"places error. here's the description: %@",error.description);
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we couldn't load any info for this location. Please try again soon!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }];
    }failure:^(NSError *error) {
        NSLog(@"error from mapview: %@",error.description);
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we don't have any info on this location. We're working on it!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
    }];
    [self.view bringSubviewToFront:self.postsContainerTableView];
}

- (void) showDetails {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView setRegion:MKCoordinateRegionMake(self.place.coordinate, MKCoordinateSpanMake(0.1, 0.1)) animated:YES];
    [self.mapView addAnnotation:self.place];
    self.placeLabel.text = self.place.name;
    self.streetAddress.text = self.place.location.address;
    self.cityStateCountry.text = [NSString stringWithFormat:@"%@, %@",self.place.location.city, self.place.location.state];
    if (self.place.categories != nil){
        self.categoryLabel.text = [NSString stringWithFormat: @"%@",[[self.place.categories valueForKey:@"name"] componentsJoinedByString:@", " ]];
        [self.categoryLabel setFrame:CGRectMake(4,self.hoursTextView.contentSize.height-20,150,50)];
    }
    if (self.place.reservationsUrl) [self.reservationsLink setHidden:NO];
    //if (self.place.menuUrl)[self.menuLink setHidden:NO];
    if (self.place.url) {
        UIBarButtonItem *websiteButton = [[UIBarButtonItem alloc] initWithTitle:@"WEBSITE" style:UIBarButtonItemStyleBordered target:self action:@selector(viewWebsite)];
        self.navigationItem.rightBarButtonItem = websiteButton;
    }
    if (self.place.totalCheckins) self.totalCheckinsLabel.text = [NSString stringWithFormat:@"%@ checkins",self.place.totalCheckins];
    else [self.totalCheckinsLabel setHidden:YES];
    self.foodiaPosts.text = [NSString stringWithFormat:@"Foodia posts: %d",self.posts.count];
}

- (IBAction)getDirections:(id)sender {
    // this uses an address for the destination.  can use lat/long, too with %f,%f format
    Class itemClass = [MKMapItem class];
    if (itemClass && [itemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate: self.place.coordinate addressDictionary: nil];
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

- (void)viewWebsite {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self performSegueWithIdentifier:@"ViewWebsite" sender:self];
}

// like or unlike the post
- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    
    if ([post isLikedByUser]) {
        [[FDAPIClient sharedClient] unlikePost:post
                                       success:^(FDPost *newPost) {
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                           [self.postsContainerTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }
         ];
        
    } else {
        [[FDAPIClient sharedClient] likePost:post
                                     success:^(FDPost *newPost) {
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         int t = [newPost.likeCount intValue] + 1;
                                         
                                         [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                         [self.postsContainerTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }
         ];
    }
}



- (IBAction)goToMenu {
    NSLog(@"should be going to menu");
}

- (IBAction)getReservation:(id)sender {
    NSLog(@"reservation sender: %@",sender);
    [self performSegueWithIdentifier:@"ShowWebview" sender:self];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.posts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 155;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        [cell.scrollView setDelegate:self];
        [cell.scrollView setContentSize:CGSizeMake(542,115)];
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        cell = [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        cell.detailPhotoButton.tag = [post.identifier integerValue];
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recButton setFrame:CGRectMake(276,52,60,34)];
        [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        [recButton setTitle:@"Rec" forState:UIControlStateNormal];
        recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        recButton.layer.borderWidth = 1.0f;
        recButton.backgroundColor = [UIColor whiteColor];
        recButton.layer.cornerRadius = 17.0f;
        recButton.layer.shouldRasterize = YES;
        recButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [recButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        recButton.tag = indexPath.row;
        [cell.scrollView addSubview:recButton];
        
        UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commentButton setFrame:CGRectMake(382,52,118,34)];
        commentButton.tag = [post.identifier integerValue];
        [commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        [commentButton setTitle:@"Add a comment..." forState:UIControlStateNormal];
        [commentButton setTitle:@"Nice!" forState:UIControlStateSelected];
        commentButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        commentButton.layer.borderWidth = 1.0f;
        commentButton.backgroundColor = [UIColor whiteColor];
        commentButton.layer.cornerRadius = 17.0f;
        commentButton.layer.shouldRasterize = YES;
        commentButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [commentButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [commentButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        [cell.scrollView addSubview:commentButton];
        
        //disable locationButton
        if (post.locationName.length){
            [cell.locationButton setHidden:NO];
            [cell.locationButton setEnabled:NO];
        }
        
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        return cell;
    } else {
        NSLog(@"no posts");
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        self.postsContainerTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
    }
}

- (void)didSelectRow:(id)sender {
    [self performSegueWithIdentifier:@"ShowPostFromPlace" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowPostFromPlace"]) {
        UIButton *button = (UIButton *)sender;
        FDPostViewController *vc = segue.destinationViewController;
        [vc setPostIdentifier:[NSString stringWithFormat:@"%d",button.tag]];
    } else if ([segue.identifier isEqualToString:@"ShowPostFromLikers"]) {
        UIButton *button = (UIButton *)sender;
        FDProfileViewController *vc = segue.destinationViewController;
        [vc initWithUserId:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"ViewWebsite"]) {
        FDWebViewController *vc = [segue destinationViewController];
        NSURL *url = [NSURL URLWithString:self.place.url];
        NSLog(@"url from placeVC: %@",url);
        [vc setUrl:url];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromLikers"]){
        UIButton *button = (UIButton *)sender;
        FDProfileViewController *vc = segue.destinationViewController;
        [vc initWithUserId:button.titleLabel.text];
    }
}

- (void)recommend:(id)sender {
    NSLog(@"should be recommending");
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    FDCustomSheet *actionSheet = [[FDCustomSheet alloc] initWithTitle:@"I'm recommending something on FOODIA!" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend via Facebook",@"Send a Text", @"Send an Email", nil];
    [actionSheet setFoodiaObject:post.foodiaObject];
    [actionSheet setPost:post];
    [actionSheet showInView:self.view];
}

- (void) actionSheet:(FDCustomSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"should be facebooking");
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                                   bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                                   bundle:nil];
        }
        FDRecommendViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RecommendView"];
        [vc setPost:actionSheet.post];
        
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound) {
            // No permissions found in session, ask for it
            [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                if (!error) {
                    if ([FBSession.activeSession.permissions
                         indexOfObject:@"publish_actions"] != NSNotFound) {
                        // If permissions granted, go to the rec controller
                        [self.navigationController pushViewController:vc animated:YES];
                        
                    } else {
                        [self dismissViewControllerAnimated:YES completion:nil];
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we'll need your permission in order to post recommendations to Facebook." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                    }
                }
            }];
        } else if ([FBSession.activeSession.permissions
                    indexOfObject:@"publish_actions"] != NSNotFound) {
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if(buttonIndex == 1) {
        NSLog(@"should be texting");
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",actionSheet.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self presentViewController:viewController animated:YES completion:nil];
        }
    } else if(buttonIndex == 2) {
        NSLog(@"should be emailing");
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", actionSheet.foodiaObject, actionSheet.post.identifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:actionSheet.foodiaObject];
            if (controller) [self presentViewController:controller animated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your recommendation. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
    } else if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your mail. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
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
    [self performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)showProfile:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIStoryboard *storyboard;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                               bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                               bundle:nil];
    }
    FDProfileViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    [vc initWithUserId:button.titleLabel.text];
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
