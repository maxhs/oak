//
//  FDGoogleAPIClient.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/17/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#define CLIENT_ID @"AIzaSyBX-S0CG3WjICI-Sgpulk3lyOZE7iYIj-E"
#define BASE_URL @"https://maps.googleapis.com/maps/api/place/search/json"

#import "FDGoogleAPIClient.h"

@implementation FDGoogleAPIClient

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);

static FDGoogleAPIClient *singleton;

+ (void)initialize {
    singleton = [[FDGoogleAPIClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    [singleton registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [singleton setDefaultHeader:@"Accept" value:@"application/json"];
    singleton.operationQueue.maxConcurrentOperationCount = 6;
}

+ (FDGoogleAPIClient *)sharedClient {
    return singleton;
}

- (void)forgetVenues {
    _venues = nil;
    _lastLocation = nil;
}

- (AFHTTPRequestOperation *)getVenuesNearLocation:(CLLocation *)location success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure {
    
    NSString *coordinateString = [NSString stringWithFormat:@"%f,%f",location.coordinate.latitude, location.coordinate.longitude];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:coordinateString,@"location", @"500", @"radius",@"food", @"types",@"true",@"sensor", nil];
    NSLog(@"paramters: %@", parameters);
    _isUpdating = YES;
    
    return [self requestOperationWithMethod:@"GET"
                                       path:BASE_URL
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        /*_venues = [self venuesFromArray:[result valueForKeyPath:@"response.venues"]];
                                        _lastLocation = location;
                                        _isUpdating = NO;
                                        if (success) success(self.venues);*/
                                        NSLog(@"google places result: %@", result);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        _isUpdating = NO;
                                        if (failure) failure(error);
                                    }
            ];
}

/*- (AFHTTPRequestOperation *)getVenuesNearLocation:(CLLocation *)location
                                        withQuery:(NSString *)query
                                          success:(void(^)(NSArray *venues))success
                                          failure:(void(^)(NSError *error))failure {
    
    NSString *coordinateString = [NSString stringWithFormat:@"%f,%f",location.coordinate.latitude, location.coordinate.longitude];
    
    NSDictionary *parameters = @{@"ll" : coordinateString, @"query" : query};
    
    _isUpdating = YES;
    
    return [self requestOperationWithMethod:@"GET"
                                       path:VENU_SEARCH_PATH
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        _venues = [self venuesFromArray:[result valueForKeyPath:@"response.venues"]];
                                        _isUpdating = NO;
                                        success(self.venues);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        _isUpdating = NO;
                                        failure(error);
                                    }
            ];
}
*/
- (AFJSONRequestOperation *)requestOperationWithMethod:(NSString *)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters success:(OperationSuccess)success failure:(OperationFailure)failure
{
    
    NSMutableDictionary *allParams = [parameters mutableCopy];
    [allParams setObject:CLIENT_ID     forKey:@"key"];
    NSLog(@"allParams: %@", allParams);
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:allParams];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                                         success:success
                                                                                         failure:failure];
    [op start];
    return op;
}

/*- (NSArray *)venuesFromArray:(NSArray *)array {
    NSMutableArray *venues = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *venueDictionary in array) {
        FDVenue *venue = [[FDVenue alloc] init];
        [venue setAttributesFromDictionary:venueDictionary];
        [venues addObject:venue];
    }
    return venues;
}*/



@end
