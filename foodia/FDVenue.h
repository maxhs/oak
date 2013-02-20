//
//  FDVenue.h
//  
//
//  Created by Max Haines-Stiles on 8/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class FDVenueContact;
@class FDVenueLocation;

@interface FDVenue : NSObject <NSCoding, MKAnnotation> {
    NSMutableArray *categories;
    FDVenueContact *contact;
    NSString *FDVenueId;
    FDVenueLocation *location;
    NSString *name;
    NSMutableArray *hours;
    NSString *likes;
    BOOL isOpen;
    BOOL verified;
}

@property (nonatomic, copy) NSMutableArray *categories;
@property (nonatomic, strong) FDVenueContact *contact;
@property (nonatomic, copy) NSString *FDVenueId;
@property (nonatomic, strong) FDVenueLocation *location;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSMutableArray *hours;
@property (nonatomic, copy) NSString *statusHours;
@property (nonatomic, copy) NSNumber *likes;
@property (nonatomic, copy) NSNumber *totalCheckins;
@property (nonatomic, copy) NSNumber *hereNow;
@property (nonatomic, copy) NSMutableArray *tips;
@property (nonatomic, copy) NSString *menuUrl;
@property (nonatomic, copy) NSMutableArray *stats;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *reservationsUrl;
@property (nonatomic, copy) NSMutableArray *posts;
@property (nonatomic, copy) NSString *imageViewUrl;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, assign) BOOL verified;

+ (FDVenue *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (FDVenue *)setAttributesFromDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

// MKAnnotation properties
- (CLLocationCoordinate2D)coordinate;
- (NSString *)title;
- (NSString *)subtitle;

@end
