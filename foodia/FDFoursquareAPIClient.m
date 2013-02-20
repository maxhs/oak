//
//  FDFoursquareAPIClient.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDFoursquareAPIClient.h"
#import "FDVenue.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import "AFHTTPClient.h"
#define VENU_SEARCH_PATH @"venues/search"
#define VENUE_BASE @"venues"
#define BASE_URL @"https://api.foursquare.com/v2/"
#define CHECKIN_PATH @"https://api.foursquare.com/v2/checkins/add"
#define CLIENT_ID @"X5ARXOQ3UMJYP12LTK5QW3SDPLZKW0L35MJNKWCPUIC4HAFR"
#define CLIENT_SECRET @"UERW4CAFZ31MRCT0MTEXNF4M1Q1KRROZJGF55V0NQ4J3U3TW"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);

@implementation FDFoursquareAPIClient

static FDFoursquareAPIClient *singleton;

+ (void)initialize {
    singleton = [[FDFoursquareAPIClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    [singleton registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [singleton setDefaultHeader:@"Accept" value:@"application/json"];
    singleton.operationQueue.maxConcurrentOperationCount = 6;
}

+ (FDFoursquareAPIClient *)sharedClient {
    return singleton;
}

- (void)forgetVenues {
    _venues = nil;
    _lastLocation = nil;
}

- (AFJSONRequestOperation *)getVenuesNearLocation:(CLLocation *)location success:(void(^)(NSArray *venues))success failure:(void(^)(NSError *error))failure {
    
    NSString *coordinateString = [NSString stringWithFormat:@"%f,%f",location.coordinate.latitude, location.coordinate.longitude];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:coordinateString,@"ll",/*@"4d4b7105d754a06374d81259,4d4b7105d754a06376d81259,4bf58dd8d48988d1f9941735,4bf58dd8d48988d117951735", @"categoryId", */@"50", @"limit",nil];
    
    _isUpdating = YES;
    
    return [self requestOperationWithMethod:@"GET"
                                       path:VENU_SEARCH_PATH parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        _venues = [self venuesFromArray:[result valueForKeyPath:@"response.venues"]];
                                        _lastLocation = location;
                                        _isUpdating = NO;
                                        if (success) success(self.venues);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        _isUpdating = NO;
                                        if (failure) failure(error);
                                    }
            ];
}

- (AFJSONRequestOperation *)getDetailsForPlace:(NSString *)venueId
                                      success:(void(^)(NSDictionary *placeDetails))success
                                      failure:(void(^)(NSError *error))failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"group",@"venue", nil];
    
    _isUpdating = YES;
    NSString *path = [NSString stringWithFormat:@"%@/%@",VENUE_BASE,venueId];
    
    return [self requestOperationWithMethod:@"GET"
                                       path:path
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        if (success) success([result valueForKeyPath:@"response.venue"]);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        _isUpdating = NO;
                                        failure(error);
                                    }
            ];
}

- (AFJSONRequestOperation *)getVenuesNearLocation:(CLLocation *)location
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

- (AFHTTPRequestOperation *)checkInVenue:(NSString *)venueId
                             postCaption:(NSString *)caption
                              withPostId:(id)postId
{
    NSString *foursquareAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"foursquare_access_token"];
    NSString *shout = [NSString stringWithFormat:@"%@. Check it out on FOODIA: http://posts.foodia.com/p/%@", caption, [postId stringValue]];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys: venueId,@"venueId",foursquareAccessToken,@"oauth_token",shout,@"shout", nil];
    return [self requestOperationWithMethod:@"POST"
                              path:CHECKIN_PATH
                        parameters:parameters
                           success:^(AFHTTPRequestOperation *operation, id result) {
                               NSLog(@"success checking in with foursquare");
                           }
                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                               [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"foursquare_access_token"];
                               [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we couldn't connect to Foursquare. Your authorization to connect with FOODIA may have expired. Please try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                           }
            ];
}


- (AFJSONRequestOperation *)requestOperationWithMethod:(NSString *)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters success:(OperationSuccess)success failure:(OperationFailure)failure
{
    
    NSMutableDictionary *allParams = [parameters mutableCopy];
    [allParams setObject:@"20120803"   forKey:@"v"];
    [allParams setObject:CLIENT_ID     forKey:@"client_id"];
    [allParams setObject:CLIENT_SECRET forKey:@"client_secret"];
    
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:allParams];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                                         success:success
                                                                                         failure:failure];
    [op start];
    return op;
}

- (NSArray *)venuesFromArray:(NSArray *)array {
    
    NSMutableArray *venues = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *venueDictionary in array) {
        FDVenue *venue = [[FDVenue alloc] init];
        [venue setAttributesFromDictionary:venueDictionary];
        [venues addObject:venue];
    }
    return venues;
}



@end
