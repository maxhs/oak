//
//  FDAPIClient.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "AFNetworking.h"
#import "FDVenue.h"
#import <CoreLocation/CoreLocation.h>

@class FDPost;

typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface FDAPIClient : AFHTTPClient

@property (nonatomic, copy) NSString *facebookID;
@property (nonatomic, copy) NSString *facebookAccessToken;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSData *deviceToken;

+ (FDAPIClient *)sharedClient;

// these methods implement the API calls, returning the request operation objects that
// connect to the API. Those objects can be used to cancel the request. Results can be
// handled via blocks

- (AFHTTPRequestOperation *)deviceConnectivity;

- (AFHTTPRequestOperation *)unfollowUser:(NSString *)userId;

- (AFHTTPRequestOperation *)followUser:(NSString *)userId;

// get a fresh feed
- (AFHTTPRequestOperation *)getInitialFeedPostsSuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure;

// get a profile feed
- (AFHTTPRequestOperation *)getFeedForProfile:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getMapForProfile:(NSString *)uid
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;


// get a profile feed before a certain post date
- (AFHTTPRequestOperation *)getProfileFeedBefore:(FDPost *)post
                                      forProfile:(NSString *)uid
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;

// gets a profile feed for a specific category
- (AFHTTPRequestOperation *)getProfileFeedForCategory:(NSString *)category
                                           forProfile:(NSString *)uid
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure;

// get a profile
- (AFJSONRequestOperation *)getProfileDetails:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure;

// get the feed since a post
- (AFHTTPRequestOperation *)getFeedPostsSincePost:(FDPost *)afterPost
                                          success:(RequestSuccess)success
                                          failure:(RequestFailure)failure;

// get the feed previous to a post
- (AFHTTPRequestOperation *)getFeedBeforePost:(FDPost *)beforePost
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure;

// get notifications
- (AFHTTPRequestOperation *)getActivitySuccess:(RequestSuccess)success
                                       failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getActivityCountSuccess:(RequestSuccess)success
                                            failure:(RequestFailure)failure;

// get the detailed version of a post
- (AFHTTPRequestOperation *)getDetailsForPostWithIdentifier:(NSString *)postIdentifier
                                                    success:(RequestSuccess)success
                                                    failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getFeaturedPostsSuccess:(RequestSuccess)success
                                            failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getFeaturedPostsSincePost:(FDPost *)sincePost
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getFeaturedPostsBeforePost:(FDPost *)beforePost
                                               success:(RequestSuccess)success
                                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getCategoryImageURLsWithSuccess:(RequestSuccess)success
                                                    failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getSearchResultsForObjectCategory:(NSString *)category
                                                        query:(NSString *)query
                                                      success:(RequestSuccess)success
                                                      failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)submitPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)editPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)deletePost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)registerUser;

- (AFJSONRequestOperation *)likePost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)unlikePost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getPostsNearLocation:(CLLocation *)location
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getPostsForPlace:(FDVenue *)venue
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;


- (AFHTTPRequestOperation *)getRecommendedPostsSuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getRecommendedPostsSincePost:(FDPost *)sincePost
                                                 success:(RequestSuccess)success
                                                 failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getRecommendedPostsBeforePost:(FDPost *)beforePost
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getPeopleListSuccess:(RequestSuccess)success failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)recommendPost:(FDPost *)post toRecommendees:(NSSet *)recommendes withMessage:(NSString *)message success:(RequestSuccess)success failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)addCommentWithBody:(NSString *)body
                                       forPost:(FDPost *)post
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure;
@end
