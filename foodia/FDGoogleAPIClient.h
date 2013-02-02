//
//  FDGoogleAPIClient.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "AFHTTPClient.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"

@interface FDGoogleAPIClient : AFHTTPClient

@property (nonatomic, readonly) NSArray *venues;
@property (nonatomic, readonly) CLLocation *lastLocation;
@property (readonly) BOOL isUpdating;
+ (FDGoogleAPIClient *)sharedClient;
- (AFHTTPRequestOperation *)getVenuesNearLocation:(CLLocation *)location success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure;
- (AFHTTPRequestOperation *)getVenuesNearLocation:(CLLocation *)location withQuery:(NSString *)query success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure;
- (AFHTTPRequestOperation *)checkInVenue:(NSString *)venueId postCaption:(NSString*)caption withPostId:(id)postId;
- (void)forgetVenues;
@end
