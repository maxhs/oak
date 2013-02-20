//
//  FDPostNearbyCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 10/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostNearbyCell.h"
#import "FDPost.h"
#import "FDUser.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"
#import "FDPlaceViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

@interface FDPostNearbyCell ()

@property (weak, nonatomic) IBOutlet UILabel *objectLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *socialLabel;

@end

@implementation FDPostNearbyCell
@synthesize userId;
static NSDictionary *placeholderImages;

+ (void)initialize {
    placeholderImages = [NSDictionary dictionaryWithObjectsAndKeys:
                         [UIImage imageNamed:@"detailPlaceholderEating.png"],   @"Eating",
                         [UIImage imageNamed:@"detailPlaceholderDrinking.png"], @"Drinking",
                         [UIImage imageNamed:@"detailPlaceholderMaking.png"],  @"Making",
                         [UIImage imageNamed:@"detailPlaceholderShopping.png"], @"Shopping", nil];
}

+ (UIImage *)placeholderImageForCategory:(NSString *)category {
    return [placeholderImages objectForKey:category];
}

+ (CGFloat)cellHeight {
    return 155;
}

// here we configure the cell to display a given post
- (void)configureForPost:(FDPost *)post {
    
    // set up the poster button
    [self.posterButton setImageWithURL:[Utilities profileImageURLForFacebookID:post.user.facebookId] forState:UIControlStateNormal];
    self.posterButton.layer.cornerRadius = 8.0f;
    self.posterButton.clipsToBounds = YES;
    
    self.userId = post.user.facebookId;
    
    if([CLLocationManager locationServicesEnabled] == true) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        CLLocationDistance mi = [post.location distanceFromLocation:locationManager.location]/1000 * 0.621371;
        self.distanceLabel.text = [NSString stringWithFormat:@"%.2f Mi", mi];
        
    } else {
        self.distanceLabel.text = @"? Mi";
    }
    
    // show the photo if present
    if (post.hasDetailPhoto) {
        [self.photoImageView setImageWithURL:post.detailImageURL];
    } else {
        [self.photoImageView setImage:[FDPostNearbyCell placeholderImageForCategory:post.category]];
    }
    
    // display map
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:post];
    [self.mapView setRegion:MKCoordinateRegionMake(post.location.coordinate, MKCoordinateSpanMake(0.02, 0.02))];
    
    // show the like count, and set the like button's image to indicate whether current user likes
    self.likeCountLabel.text = [NSString stringWithFormat:@"%@", post.likeCount];
    UIImage *likeButtonImage;
    if (post.isLikedByUser) {
        likeButtonImage = [UIImage imageNamed:@"feedLikeButtonRed.png"];
    } else {
        likeButtonImage = [UIImage imageNamed:@"feedLikeButtonGray.png"];
    }
    [self.likeButton setImage:likeButtonImage forState:UIControlStateNormal];
    
    // show the social string for the post
    self.placeLabel.text = post.locationName;

    // show the foodia object
    self.socialLabel.text = post.foodiaObject;
    
}

@end
