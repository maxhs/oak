//
//  FDFoursquareAPIClient.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDVenue.h"
#import "AFNetworking.h"
#import <CoreLocation/CoreLocation.h>
#import "FDAPIClient.h"

@interface FDFoursquareAPIClient : AFHTTPClient
@property (nonatomic, readonly) NSArray *venues;
@property (nonatomic, readonly) CLLocation *lastLocation;
@property (readonly) BOOL isUpdating;
+ (FDFoursquareAPIClient *)sharedClient;
- (AFJSONRequestOperation *)getVenuesNearLocation:(CLLocation *)location success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure;
- (AFJSONRequestOperation *)getVenuesNearLocation:(CLLocation *)location withQuery:(NSString *)query success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure;
- (AFJSONRequestOperation *)getDetailsForPlace:(NSString *)venueId
                                       success:(void(^)(NSDictionary *placeDetails))success
                                       failure:(void(^)(NSError *error))failure;
- (AFHTTPRequestOperation *)checkInVenue:(NSString *)venueId postCaption:(NSString*)caption withPostId:(id)postId;
- (void)forgetVenues;
@end
