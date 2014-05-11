//
//  FDAPIClient.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "AFNetworking.h"
#import "FDVenue.h"
#import "FDUser.h"
#import "FDNotification.h"
#import <CoreLocation/CoreLocation.h>

@class FDPost;

typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface FDAPIClient : AFHTTPClient

@property (nonatomic, copy) NSData *deviceToken;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) AFJSONRequestOperation *postOp;
@property (nonatomic, strong) AFJSONRequestOperation *editPostOp;

+ (FDAPIClient *)sharedClient;

// these methods implement the API calls, returning the request operation objects that
// connect to the API. Those objects can be used to cancel the request. Results can be
// handled via blocks

- (AFJSONRequestOperation *)connectUser:(NSString*)name
                                  email:(NSString*)email
                                password:(NSString*)password
                                 signup:(BOOL) signup
                                   fbid:(NSString*)facebookId
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)forgotPassword:(NSString*)email
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)updateProfileDetails:(NSNumber *)userId
                                            name:(NSString *)name
                                        location:(NSString *)location
                                       userPhoto:(UIImage *)userImage
                                      philosophy:(NSString *)philosophy
                                        password:(NSString*)password
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getProfilePic:(NSString *)userId
                                  success:(RequestSuccess)success
                                  failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)unfollowUser:(NSString *)userId;

- (AFHTTPRequestOperation *)followUser:(NSString *)userId;

- (AFHTTPRequestOperation *)checkIfUser:(NSString *)userId
                                success:(RequestSuccess)success
                                failure:(RequestFailure)failure;
// get a fresh feed
- (AFHTTPRequestOperation *)getInitialFeedPostsSuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getPostsFromTimePeriod:(NSString *)uid
                                           success:(RequestSuccess)success
                                           failure:(RequestFailure)failure;

// get tag stuff
- (AFJSONRequestOperation *)getTagsForTimePeriod:(NSString *)timePeriod
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getPostsForTag:(NSString *)tagName
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getUserPostsForTag:(NSString *)tagName
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getTagsForFoodiaObject:(NSString *)foodiaObject
                                           success:(RequestSuccess)success
                                           failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getTagsForUserSuccess:(RequestSuccess)success
                                          failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)trackTag:(NSString*)tagName
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)removeTrackedTag:(NSString *)tagIdentifier
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getTrackedTagsForTimePeriod:(NSString*)timePeriod
                                                success:(RequestSuccess)success
                                                failure:(RequestFailure)failure;

// get a profile feed
- (AFHTTPRequestOperation *)getFeedForProfile:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getMapForProfile:(NSString *)uid
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;

// get user settings
- (AFJSONRequestOperation *)getUserSettingsSuccess:(RequestSuccess)success
                                           failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)updateUserSettings:(FDUser*)user
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure;

//hold a post, and get the held feed
- (AFHTTPRequestOperation *)holdPost:(NSString*)postIdentifier;
- (AFHTTPRequestOperation *)removeHeldPost:(NSString*)postIdentifier
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)removeRecPost:(NSString*)postIdentifier
                                  success:(RequestSuccess)success
                                  failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getHeldPosts:(RequestSuccess)success
                                  failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getHeldPostsSincePost:(FDPost *)sincePost
                                            success:(RequestSuccess)success
                                            failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getHeldPostsByPopularity:(RequestSuccess)success
                                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getHeldPostsFromLocation:(CLLocation*)location
                                             success:(RequestSuccess)success
                                             failure:(RequestFailure)failure;

// get a profile feed before a certain post date
- (AFHTTPRequestOperation *)getProfileFeedBefore:(FDPost *)post
                                      forProfile:(NSString *)uid
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;

// gets a profile feed for a specific category
- (AFHTTPRequestOperation *)getProfileFeedForCategory:(NSString *)category
                                        andTimePeriod:(NSString *)timePeriod
                                           forProfile:(NSString *)uid
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getCategoryCountsForTime:(NSString *)timePeriod
                                             success:(RequestSuccess)success
                                             failure:(RequestFailure)failure;

// get a profile
- (AFJSONRequestOperation *)getProfileDetails:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getFollowers:(NSString *)uid
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getFollowing:(NSString *)uid
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getFollowingIds:(NSString *)uid
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

- (AFHTTPRequestOperation *)getActivityBeforeNotification:(FDNotification*)notification
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure;
- (AFHTTPRequestOperation *)getActivitySinceNotification:(FDNotification*)notification
                                                 success:(RequestSuccess)success
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

- (AFHTTPRequestOperation *)getPostsForQuery:(NSString*)query
                                 andLocation:(NSString*)locationQuery
                                     Success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;
- (AFHTTPRequestOperation *)getPopularPostsForQuery:(NSString*)query
                                            Success:(RequestSuccess)success
                                            failure:(RequestFailure)failure;
- (AFHTTPRequestOperation *)getDistancePostsForQuery:(NSString*)query
                                        withLocation:(CLLocation*)currentLocation
                                             Success:(RequestSuccess)success
                                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getCategoryImageURLsWithSuccess:(RequestSuccess)success
                                                    failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getUsersForQuery:(NSString *)query
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;

//object and tag searches
- (AFJSONRequestOperation *)getSearchResultsForObjectCategory:(NSString *)category
                                                        query:(NSString *)query
                                                      success:(RequestSuccess)success
                                                      failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)getSearchResultsForTagQuery:(NSString *)query
                                                success:(RequestSuccess)success
                                                failure:(RequestFailure)failure;

//get venues
- (AFJSONRequestOperation *)getVenuesForUser:(NSString *)userId
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getUserPosts:(NSString *)userId
                                forQuery:(NSString *)query
                               withVenue:(NSString *)venue
                        nearCoordinate:(CLLocation *)location
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)submitPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)quickPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)editPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)deletePost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)likePost:(FDPost *)post
                              detail:(BOOL)detail
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)unlikePost:(FDPost *)post
                                detail:(BOOL)detail
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getPostsNearLocation:(CLLocation *)location
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getPostsForPlace:(FDVenue *)venue
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure;


- (AFHTTPRequestOperation *)getRecommendedPostsByPopularity:(BOOL)popularity
                                                 distance:(CLLocation *)location
                                                  Success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getRecommendedPostsSincePost:(FDPost *)sincePost
                                                 success:(RequestSuccess)success
                                                 failure:(RequestFailure)failure;

- (AFHTTPRequestOperation *)getRecommendedPostsBeforePost:(FDPost *)beforePost
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)getPeopleListSuccess:(RequestSuccess)success failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)recommendPost:(FDPost *)post onFacebook:(BOOL)facebook toRecommendees:(NSSet *)recommendes withMessage:(NSString *)message success:(RequestSuccess)success failure:(RequestFailure)failure;
- (AFJSONRequestOperation *)recommendPostOnFacebook:(FDPost *)post
                                            success:(RequestSuccess)success
                                            failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)addCommentWithBody:(NSString *)body
                                       forPost:(FDPost *)post
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure;

- (AFJSONRequestOperation *)deleteCommentWithId:(NSNumber *)commentId
                                      forPostId:(NSNumber*)postId
                                        success:(RequestSuccess)success
                                        failure:(RequestFailure)failure;
@end
