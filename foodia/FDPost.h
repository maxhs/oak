//
//  FDPost.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDRecord.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class FDUser, FDVenue;

@interface FDPost : FDRecord <MKAnnotation>

@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * foodiaObject;
@property (nonatomic, retain) NSString * feedImageUrlString;
@property (nonatomic, retain) NSString * detailImageUrlString;
@property (nonatomic, retain) NSString * featuredImageUrlString;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * epochTime;
@property (nonatomic, retain) NSNumber * isRecommendedToUser;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSNumber * recCount;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * viewCount;
@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) NSString * locationHours;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * foursquareid;
@property (nonatomic, retain) FDUser   * user;
@property (nonatomic, retain) NSSet    * withFriends;
@property (nonatomic, retain) NSSet    * recommendedTo;
@property (nonatomic, retain) NSNumber * recommendedEpochTime;
@property (nonatomic, retain) NSNumber * featuredEpochTime;
@property (nonatomic, retain) NSDictionary    * likers;
@property (nonatomic, retain) NSDictionary    * viewers;
@property (nonatomic, retain) NSSet    * comments;
@property (nonatomic, retain) FDVenue  * venue;
@property (nonatomic, retain) NSString *FDVenueId;
@property (nonatomic, strong) UIImage  * photoImage;
@property (nonatomic, retain) CLLocation  * location;
@property (nonatomic) BOOL  * customVenue;
@property (nonatomic, retain) NSNumber *postId;
@property (nonatomic, retain) NSString *og;
+ (FDPost *)userPost;
+ (void)setUserPost:(FDPost *)post;
+ (void)resetUserPost;
- (NSDate *)recommendedAt;
-(Boolean) isLikedByUser;
- (NSDate *)postedAt;
- (NSURL *)feedImageURL;
- (NSURL *)detailImageURL;
- (NSURL *)featuredImageURL;
- (void)setLocation:(CLLocation *)location;
- (void)setVenue:(FDVenue *)venue;
- (BOOL)hasPhoto;
- (BOOL)hasDetailPhoto;
- (NSString *)socialString;
- (NSString *)detailString;
- (CLLocationCoordinate2D)coordinate;
- (NSString *)title;
@end
