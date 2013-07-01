//
//  FDAPIClient.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//
//  This class is used to communicate with the Foodia API
//
//  All of the methods that initiate a request to the API
//  return the AFHTTPRequestOperation associated with the
//  request. This allows the requesting object (usually a
//  view controller) to cancel the request easily.
//
//  Rather than using a delegate pattern to return results,
//  the get methods accept block parameters to execute when
//  a request operation is completed.
//

#import "FDAPIClient.h"
#import "FDPost.h"
#import <CoreLocation/CoreLocation.h>
#import "Post.h"
#import "FDVenueLocation.h"
#import "FDCache.h"
#import "FDAppDelegate.h"
#import "FDComment.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FDFoodiaTag.h"

#define BASE_URL @"http://posts.foodia.com/api/v4"
#define CONNECTIVITY_PATH @"apn_registrations"
#define SESSION_PATH @"sessions"
#define FORGOT_PASSWORD_PATH @"sessions/forgot_password.json"
#define FEED_PATH @"posts.json"
#define FEATURED_PATH @"posts/featured.json"
#define PROFILE_PATH @"user.json"
#define USER_SEARCH_PATH @"user/search.json"
#define SETTINGS_PATH @"user/settings.json"
#define PROFILE_FEED_PATH @"posts/profile.json"
#define USER_PLACE_SEARCH_PATH @"user/place_search.json"
#define USER_POST_SEARCH_PATH @"user/post_search.json"
#define RECOMMENDED_PATH @"posts/recommended.json"
#define ACTIVITY_PATH @"user_notifications.json"
#define ACTIVITY_COUNT_PATH @"new_notifications.json"
#define CATEGORY_IMAGE_PATH @"category_images.json"
#define OBJECT_SEARCH_PATH @"foodia_objects.json"
#define TAG_SEARCH_PATH @"foodia_tags.json"
#define TAGS_POSTS_PATH @"foodia_tags/tags_posts.json"
#define POSTS_TAGS_PATH @"foodia_tags/posts_tags.json"
#define FOOD_OBJECT_TAGS_PATH @"foodia_tags/foodia_objects.json"
#define POST_SUBMISSION_PATH @"posts"
#define QUICK_POST_SUBMISSION_PATH @"posts/quick_post"
#define POST_UPDATE_PATH @"posts"
#define LIKE_PATH @"likes"
#define HELD_PATH @"post_holds"
#define COMMENT_PATH @"comments"
#define MAP_PATH @"posts/map.json"
#define PLACES_PATH @"posts/places.json"
#define FREE_SEARCH_PATH @"posts/free_search.json"
#define POPULAR_SEARCH_PATH @"posts/search_popular.json"
#define DISTANCE_SEARCH_PATH @"posts/search_distance.json"
#define TIME_SEARCH_PATH @"posts/time_search.json"
#define CATEGORY_COUNT_PATH @"posts/category_count.json"
#define PEOPLE_PATH @"follows"
#define FOLLOWERS_PATH @"follows/followers.json"
#define FOLLOWING_PATH @"follows/following.json"
#define FOLLOWING_IDS_PATH @"follows/following_ids.json"
#define RECOMMEND_PATH @"recommendations"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);

@interface FDAPIClient () <UIAlertViewDelegate>

@end

@implementation FDAPIClient

@synthesize deviceToken, postOp, editPostOp;

static FDAPIClient *singleton;

//
// this method is called once when the class is first loaded
// we use it to intialize our singleton instance
//
+ (void)initialize {
    singleton = [[FDAPIClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    [singleton registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [singleton setDefaultHeader:@"Accept" value:@"application/json"];
    singleton.operationQueue.maxConcurrentOperationCount = 6;
}

+ (FDAPIClient *)sharedClient {
    return singleton;
}

- (AFHTTPRequestOperation *)deviceConnectivity
{
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to get device connectivity: %@", error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {};
    return [self requestOperationWithMethod:@"POST"
                                       path:CONNECTIVITY_PATH
                                 parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.deviceToken, @"device_token", nil]
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)unfollowUser:(NSString *)userId
{
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {

    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
    };
    return [self requestOperationWithMethod:@"GET"
                                       path:[PEOPLE_PATH stringByAppendingFormat:@"/%@",userId]
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}



- (AFHTTPRequestOperation *)followUser:(NSString *)userId
{
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {};
    return [self requestOperationWithMethod:@"POST"
                                       path:PEOPLE_PATH
                                 parameters:[NSDictionary dictionaryWithObjectsAndKeys:userId, @"friend_id", nil]
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)checkIfUser:(NSString *)userId
                                success:(RequestSuccess)success
                                failure:(RequestFailure)failure {
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error checking for user: %@",error.description);
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([responseObject objectForKey:@"success"]);
    };
    return [self requestOperationWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"user/%@",userId]
                                 parameters:[NSDictionary dictionaryWithObjectsAndKeys:userId, @"friend_id", nil]
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Feed methods

//
// used to get the feed for the first time
//

- (AFHTTPRequestOperation *)getInitialFeedPostsSuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure
{
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *posts = [self postsFromJSONArray:[responseObject objectForKey:@"posts"]];
        success(posts);
    };

    return [self requestOperationWithMethod:@"GET"
                                       path:FEED_PATH
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}


#pragma mark - Profile methods
// Profile Details
- (AFJSONRequestOperation *)getProfileDetails:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"user_id",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"current_user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([responseObject objectForKey:@"user"]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        //[(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:PROFILE_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFJSONRequestOperation *)getFollowers:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"user_id",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"current_user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self usersFromJSONArray:[responseObject objectForKey:@"followships"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        //[(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:FOLLOWERS_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFJSONRequestOperation *)getFollowing:(NSString *)uid
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"user_id",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"current_user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self usersFromJSONArray:[responseObject objectForKey:@"followships"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        //[(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:FOLLOWING_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFJSONRequestOperation *)getFollowingIds:(NSString *)uid
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"user_id",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"current_user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([responseObject objectForKey:@"following_ids"]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:FOLLOWING_IDS_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}


- (AFJSONRequestOperation *)updateProfileDetails:(NSNumber *)userId
                                            name:(NSString *)name
                                        location:(NSString *)location
                                       userPhoto:(UIImage *)userImage
                                      philosophy:(NSString *)philosophy
                                        password:(NSString*)password
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure
{
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:name,@"user[name]", location,@"user[location]", nil];
    if (philosophy.length) [parameters setObject:philosophy forKey:@"user[philosophy]"];
    if (password.length) [parameters setObject:password forKey:@"user[password]"];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        FDUser *user = [[FDUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        success(user);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"update profile details ERROR: %@", error.description);
        failure(error);
    };
    
    NSData *imageData = UIImageJPEGRepresentation(userImage, 1.0);
    NSURLRequest *request = [self multipartFormRequestWithMethod:@"PUT"
                                              path:[NSString stringWithFormat:@"user/%@",userId]
                                        parameters:parameters
                         constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
                             [formData appendPartWithFileData:imageData name:@"user[avatar]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                         }
               ];

AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                             success:opSuccess
                                                             failure:opFailure];
    [op start];
    return op;
}

- (AFJSONRequestOperation *)getUserSettingsSuccess:(RequestSuccess)success
                                           failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        FDUser *user = [[FDUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        success(user);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:SETTINGS_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFJSONRequestOperation *)updateUserSettings:(FDUser*)user
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = @{@"id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"push_smile":[NSString stringWithFormat:@"%d",user.pushSmile], @"push_geofence":[NSString stringWithFormat:@"%d",user.pushGeofence], @"push_comment":[NSString stringWithFormat:@"%d",user.pushComment], @"push_feature":[NSString stringWithFormat:@"%d",user.pushFeature], @"push_follow":[NSString stringWithFormat:@"%d",user.pushFollow], @"email_notifications":[NSString stringWithFormat:@"%d",user.emailNotifications]};
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        //FDUser *user = [[FDUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        success(responseObject);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFJSONRequestOperation *op = [self requestOperationWithMethod:@"PUT"
                                                             path:[NSString stringWithFormat:@"user/%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}


- (AFJSONRequestOperation *)getProfilePic:(NSString *)userId
                                  success:(RequestSuccess)success
                                  failure:(RequestFailure)failure {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:userId,@"user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject objectForKey:@"avatar_url"] != [NSNull null]){
            success([NSURL URLWithString:[responseObject objectForKey:@"avatar_url"]]);
        }
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    return [self requestOperationWithMethod:@"GET"
                                                             path:@"user/profile_pic.json"
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
}

// Profile feed (i.e. feed with only posts by the user)

- (AFHTTPRequestOperation *)getFeedForProfile:(NSString *)uid
                                      success:(RequestSuccess)success
                                    failure:(RequestFailure)failure
{
    NSDictionary *parameters;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] isEqualToString:uid]){
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"profile_id",@"true",@"my_profile", nil];
    } else {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"profile_id", nil];
    }
    
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFHTTPRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:PROFILE_FEED_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFHTTPRequestOperation *)getMapForProfile:(NSString *)uid
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = @{@"user_id":uid};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFHTTPRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:MAP_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

- (AFHTTPRequestOperation *)getPostsFromTimePeriod:(NSString *)timePeriod
                                           success:(RequestSuccess)success
                                           failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],timePeriod:timePeriod};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFHTTPRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:TIME_SEARCH_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}


- (AFHTTPRequestOperation *)getProfileFeedBefore:(FDPost *)beforePost
                                      forProfile:(NSString *)uid
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure
{
    NSString *moreProfile = [NSString stringWithFormat:@"%@,%@", uid, beforePost.epochTime];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:moreProfile,@"more_profile_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:PROFILE_FEED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getProfileFeedForCategory:(NSString *)category
                                        andTimePeriod:(NSString *)timePeriod
                                           forProfile:(NSString *)uid
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure {
    NSString *categoryForProfile = [NSString stringWithFormat:@"%@,%@", uid, category];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:categoryForProfile,@"category_name",timePeriod, timePeriod, nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FEED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getCategoryCountsForTime:(NSString *)timePeriod
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure {
    NSDictionary *parameters = @{timePeriod:timePeriod,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:CATEGORY_COUNT_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getActivitySuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure
{
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
       // [(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self notificationsFromJSONArray:responseObject]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:ACTIVITY_PATH
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getActivityBeforeNotification:(FDNotification*)notification
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"before_date":notification.epochTime};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self notificationsFromJSONArray:responseObject]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:ACTIVITY_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getActivitySinceNotification:(FDNotification*)notification
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"since_date":notification.epochTime};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self notificationsFromJSONArray:responseObject]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:ACTIVITY_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getActivityCountSuccess:(RequestSuccess)success
                                       failure:(RequestFailure)failure
{
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([responseObject objectForKey:@"notifications"]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:ACTIVITY_COUNT_PATH
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}

//
// used to update an existing feed. asks the API for posts that were made
// since the given post.
//

- (AFHTTPRequestOperation *)getFeedPostsSincePost:(FDPost *)sincePost 
                                          success:(RequestSuccess)success
                                          failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:sincePost.epochTime,@"since_date", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *posts = [self postsFromJSONArray:[responseObject objectForKey:@"posts"]];
        success(posts);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    AFHTTPRequestOperation *op = [self requestOperationWithMethod:@"GET"
                                                             path:FEED_PATH
                                                       parameters:parameters
                                                          success:opSuccess
                                                          failure:opFailure];
    return op;
}

//
// used to add additional posts to the bottom of the feed. Asks the API for posts
// previous to a given post.
//

- (AFHTTPRequestOperation *)getFeedBeforePost:(FDPost *)beforePost
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:beforePost.epochTime,@"before_date", nil];

    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };

    return [self requestOperationWithMethod:@"GET"
                                       path:FEED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Featured Post Methods

- (AFHTTPRequestOperation *)getFeaturedPostsSuccess:(RequestSuccess)success
                                            failure:(RequestFailure)failure
{
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        //[(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FEATURED_PATH
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getFeaturedPostsSincePost:(FDPost *)sincePost
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:sincePost.featuredEpochTime,@"since_date", nil];

    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FEATURED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}



- (AFHTTPRequestOperation *)getFeaturedPostsBeforePost:(FDPost *)beforePost
                                               success:(RequestSuccess)success
                                               failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:beforePost.featuredEpochTime,@"before_date", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FEATURED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - FREE search Post Methods

- (AFHTTPRequestOperation *)getPostsForQuery:(NSString*)query
                                     Success:(RequestSuccess)success
                                     failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"search":query};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FREE_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getDistancePostsForQuery:(NSString*)query
                                        withLocation:(CLLocation*)currentLocation
                                     Success:(RequestSuccess)success
                                     failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"search":query, @"latitude":[NSString stringWithFormat:@"%f",currentLocation.coordinate.latitude], @"longitude":[NSString stringWithFormat:@"%f",currentLocation.coordinate.longitude]};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:DISTANCE_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}
- (AFHTTPRequestOperation *)getPopularPostsForQuery:(NSString*)query
                                     Success:(RequestSuccess)success
                                     failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"search":query};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:POPULAR_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - recommended Post Methods

- (AFHTTPRequestOperation *)getRecommendedPostsByPopularity:(BOOL)popularity
                                                 distance:(CLLocation *)location
                                                  Success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (location) {
        [parameters setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude]forKey:@"latitude"];
        [parameters setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude]forKey:@"longitude"];
    }
    if (popularity) {
        [parameters setObject:[NSNumber numberWithBool:popularity] forKey:@"popularity"];
    }
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:RECOMMENDED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}



- (AFHTTPRequestOperation *)getRecommendedPostsSincePost:(FDPost *)sincePost
                                                 success:(RequestSuccess)success
                                                 failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:sincePost.recommendedEpochTime,@"since_date", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:RECOMMENDED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}



- (AFHTTPRequestOperation *)getRecommendedPostsBeforePost:(FDPost *)beforePost
                                                  success:(RequestSuccess)success
                                                  failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:beforePost.recommendedEpochTime,@"before_date", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:RECOMMENDED_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}


#pragma mark - Post Detail Methods

- (AFHTTPRequestOperation *)getDetailsForPostWithIdentifier:(NSString *)postIdentifier
                                                    success:(RequestSuccess)success
                                                    failure:(RequestFailure)failure
{
    NSString *pathForPost = [NSString stringWithFormat:@"posts/%@.json", postIdentifier];
    NSDictionary *parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        FDPost *post = [[FDPost alloc] initWithDictionary:[responseObject objectForKey:@"post"]];
        success(post);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:pathForPost
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}


#pragma mark - Category Image Methods

- (AFJSONRequestOperation *)getCategoryImageURLsWithSuccess:(RequestSuccess)success
                                                    failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"big":@"awesome"};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([responseObject objectForKey:@"imageURLs"]);
    };
    
    if ([UIScreen mainScreen].bounds.size.height == 568){
        return [self requestOperationWithMethod:@"GET"
                                           path:CATEGORY_IMAGE_PATH
                                     parameters:parameters
                                        success:opSuccess
                                        failure:opFailure];
    } else {
        return [self requestOperationWithMethod:@"GET"
                                           path:CATEGORY_IMAGE_PATH
                                     parameters:nil
                                        success:opSuccess
                                        failure:opFailure];
    }
        
}

#pragma mark - User Searching

- (AFJSONRequestOperation *)getUsersForQuery:(NSString *)query
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:query,@"search", nil];
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self usersFromJSONArray:[responseObject objectForKey:@"users"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:USER_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Foodia Object Searching

- (AFJSONRequestOperation *)getSearchResultsForObjectCategory:(NSString *)category
                                                        query:(NSString *)query
                                                      success:(RequestSuccess)success
                                                      failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:category,@"type",query,@"search", nil];
        
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([responseObject objectForKey:@"objects"]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:OBJECT_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Foodia Tag Searching

- (AFJSONRequestOperation *)getSearchResultsForTagQuery:(NSString *)query
                                                success:(RequestSuccess)success
                                                failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"search":query};
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([responseObject objectForKey:@"tags"]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:TAG_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getTagsForTimePeriod:(NSString *)timePeriod
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],timePeriod:timePeriod};
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self tagsFromJSONArray:[responseObject objectForKey:@"tags"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:TAGS_POSTS_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getPostsForTag:(NSString *)tagName
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"tag_name":[tagName stringByReplacingOccurrencesOfString:@"#" withString:@""]};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:POSTS_TAGS_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getUserPostsForTag:(NSString *)tagName
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"tag_name":[tagName stringByReplacingOccurrencesOfString:@"#" withString:@""],@"this_user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:POSTS_TAGS_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getTagsForFoodiaObject:(NSString *)foodiaObject
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure {
    NSDictionary *parameters = @{@"foodia_object":foodiaObject,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Error getting tags for %@: %@",foodiaObject, error.description);
        failure(error);
    };
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self tagsFromJSONArray:[responseObject objectForKey:@"foodia_tags"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:FOOD_OBJECT_TAGS_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getVenuesForUser:(NSString *)userId
                                     success:(RequestSuccess)success
                                     failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:userId,@"user_id", nil];
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([responseObject objectForKey:@"locations"]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:USER_PLACE_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getUserPosts:(NSString *)userId
                                forQuery:(NSString *)query
                               withVenue:(NSString *)venue
                          nearCoordinate:(CLLocation *)location
                                 success:(RequestSuccess)success
                                 failure:(RequestFailure)failure {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:userId,@"user_id",nil];
    if (query.length) [parameters setObject:query forKey:@"search_string"];
    if (venue.length) [parameters setObject:venue forKey:@"venue_string"];
    if (location) {
        [parameters setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"latitude"];
        [parameters setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
    }
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:USER_POST_SEARCH_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Nearby Posts

- (AFJSONRequestOperation *)getPostsNearLocation:(CLLocation *)location
                                          success:(RequestSuccess)success
                                            failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f",location.coordinate.latitude], @"latitude", [NSString stringWithFormat:@"%f",location.coordinate.longitude], @"longitude", nil];
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:@"nearby"
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)holdPost:(NSString*)postIdentifier {
    NSDictionary *parameters = @{@"post[identifier]":postIdentifier};
    return [self requestOperationWithMethod:@"POST" path:HELD_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error holding post: %@",error.description);
    }];
}

- (AFHTTPRequestOperation *)removeHeldPost:(NSString*)postIdentifier
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure
{
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    NSDictionary *parameters = @{@"id":postIdentifier};
    return [self requestOperationWithMethod:@"DELETE" path:[NSString stringWithFormat:@"%@/%@",HELD_PATH,postIdentifier] parameters:parameters success:opSuccess failure:opFailure];
}

- (AFHTTPRequestOperation *)removeRecPost:(NSString*)postIdentifier
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure
{
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    NSDictionary *parameters = @{@"identifier":postIdentifier, @"recipient_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]};
    return [self requestOperationWithMethod:@"GET" path:@"posts/remove_rec.json" parameters:parameters success:opSuccess failure:opFailure];
}

- (AFJSONRequestOperation *)getHeldPosts:(RequestSuccess)success
                                  failure:(RequestFailure)failure
{
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:HELD_PATH
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getHeldPostsByPopularity:(RequestSuccess)success
                                             failure:(RequestFailure)failure
{
    NSDictionary *parameters = @{@"popularity":@"TRUE"};
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error sorting by popularity: %@",error.description);
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:HELD_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFJSONRequestOperation *)getHeldPostsFromLocation:(CLLocation*)location
                                             success:(RequestSuccess)success
                                             failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f",location.coordinate.latitude], @"latitude", [NSString stringWithFormat:@"%f",location.coordinate.longitude], @"longitude", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:HELD_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

- (AFHTTPRequestOperation *)getHeldPostsSincePost:(FDPost *)sincePost
                                            success:(RequestSuccess)success
                                            failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:sincePost.epochTime,@"since_date", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:HELD_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Posts for Nearby Place

- (AFHTTPRequestOperation *)getPostsForPlace:(FDVenue *)venue
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:venue.FDVenueId, @"foursquareid", nil];
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:PLACES_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - Post Submission

- (AFJSONRequestOperation *)submitPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsPosting];
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"post[posted_at]",post.category,@"post[category_name]",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"post[user_id]",nil];
    if (post.isPrivate){
        [parameters setObject:@"true" forKey:@"post[private]"];
    }
    
    if (post.tagArray) {
        NSMutableArray *tempTagArray = [NSMutableArray array];
        for (FDFoodiaTag *tag in post.tagArray){
            [tempTagArray addObject:tag.name];
        }
        [parameters setObject:[tempTagArray componentsJoinedByString:@","] forKey:@"post[tags]"];
    }
    
    if (post.foodiaObject.length) {
        [parameters setObject:post.foodiaObject forKey:@"post[object_string]"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]) {
        [parameters setObject:post.foodiaObject
                       forKey:@"post[og]"];
    }
    if (post.withFriends.count) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.withFriends.count];
        for (FDUser *user in post.withFriends) {
            if (user.fbid){
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|fbid", user.fbid, user.name]];
            } else {
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|userId", user.userId, user.name]];
            }
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[with_friends]"];
    }
    if (post.recommendedTo.count) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.recommendedTo.count];
        for (FDUser *user in post.recommendedTo) {
            if (user.fbid){
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|fbid", user.fbid, user.name]];
            } else {
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|userId", user.userId, user.name]];
            }
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[recommend_friends]"];
    }
    if (post.caption.length){[parameters setObject:post.caption
                                     forKey:@"post[message]"];}
    if (post.location){
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.latitude]
                       forKey:@"post[location_latitude]"];
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.longitude]
                       forKey:@"post[location_longitude]"];
    }
    if (post.locationName.length){
        [parameters setObject:post.locationName
                       forKey:@"post[location_name]"];
    }
    if (post.FDVenueId.length){
        [parameters setObject:post.FDVenueId forKey:@"post[foursquareid]"];
    }
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id result) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kIsPosting];
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    NSURLRequest *request;
    if (post.photoImage) {
        UIImage *imageToPost = [self fixOrientation:post.photoImage];
        NSData *imageData = UIImageJPEGRepresentation(imageToPost, 0.5);
        request = [self multipartFormRequestWithMethod:@"POST"
                                                                path:POST_SUBMISSION_PATH
                                                          parameters:parameters
                                           constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
                                               [formData appendPartWithFileData:imageData name:@"post[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                                           }
                                 ];
            //save post image locally
            [self savePostToLibrary:imageToPost];
        } else {
            request = [self requestWithMethod:@"POST" path:POST_SUBMISSION_PATH parameters:parameters];
        }
    
    self.postOp = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                 success:opSuccess
                                                                 failure:opFailure];
    [self.postOp start];
    return self.postOp;
}

- (UIImage *)fixOrientation:(UIImage*)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)savePostToLibrary:(UIImage*)originalImage {
    NSString *albumName = @"FOODIA";
    UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    [library addAssetsGroupAlbumWithName:albumName
                             resultBlock:^(ALAssetsGroup *group) {
                                 
                             }
                            failureBlock:^(NSError *error) {
                                NSLog(@"error adding album");
                            }];
    
    __block ALAssetsGroup* groupToAddTo;
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                   
                                   groupToAddTo = group;
                               }
                           }
                         failureBlock:^(NSError* error) {
                             NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                         }];
    
    [library writeImageToSavedPhotosAlbum:imageToSave.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error.code == 0) {
            // try to get the asset
            [library assetForURL:assetURL
                     resultBlock:^(ALAsset *asset) {
                         // assign the photo to the album
                         [groupToAddTo addAsset:asset];
                     }
                    failureBlock:^(NSError* error) {
                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                    }];
        }
        else {
            NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
        }
    }];
}

- (AFJSONRequestOperation *)quickPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure {
    
    
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"post[posted_at]",post.category,@"post[category_name]",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"post[user_id]",nil];
    //quick posts are all private
    [parameters setObject:@"true" forKey:@"post[private]"];
    
    if (post.tagArray) {
        NSMutableArray *tempTagArray = [NSMutableArray array];
        for (FDFoodiaTag *tag in post.tagArray){
            [tempTagArray addObject:tag.name];
        }
        [parameters setObject:[tempTagArray componentsJoinedByString:@","] forKey:@"post[tags]"];
    }
    
    if (post.foodiaObject.length) {
        [parameters setObject:post.foodiaObject forKey:@"post[object_string]"];
    }

    if (post.location){
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.latitude]
                       forKey:@"post[location_latitude]"];
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.longitude]
                       forKey:@"post[location_longitude]"];
    }
    if (post.locationName.length){
        [parameters setObject:post.locationName
                       forKey:@"post[location_name]"];
    }
    if (post.FDVenueId.length){
        [parameters setObject:post.FDVenueId forKey:@"post[foursquareid]"];
    }
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id result) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kIsPosting];
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    NSURLRequest *request = [self requestWithMethod:@"POST" path:POST_SUBMISSION_PATH parameters:parameters];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                 success:opSuccess
                                                                 failure:opFailure];
    
    [op start];

    return op;
}

#pragma mark - DELETE Post
- (AFJSONRequestOperation *)deletePost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure {
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id result) {
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
        NSLog(@"failure from delete post method: %@", error.description);
    };
    
    return [self requestOperationWithMethod:@"DELETE"
                                       path:[NSString stringWithFormat:@"posts/%@",post.identifier]
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}

#pragma mark - EDIT Post

- (AFJSONRequestOperation *)editPost:(FDPost *)post
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsEditingPost];
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"post[posted_at]",post.foodiaObject,@"post[object_string]",post.category,@"post[category_name]",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"user_id", nil];
    
    if (post.isPrivate){
        [parameters setObject:@"true" forKey:@"post[private]"];
    } else {
        [parameters setObject:@"false" forKey:@"post[private]"];
    }
    
    if (post.tagArray) {
        NSMutableArray *tempTagArray = [NSMutableArray array];
        for (FDFoodiaTag *tag in post.tagArray){
            [tempTagArray addObject:tag.name];
        }
        [parameters setObject:[tempTagArray componentsJoinedByString:@","] forKey:@"post[tags]"];
    }
    
    if (post.withFriends.count) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.withFriends.count];
        for (FDUser *user in post.withFriends) {
            if (user.fbid){
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|fbid", user.fbid, user.name]];
            } else {
                [mutableArray addObject:[NSString stringWithFormat:@"%@|%@|userId", user.userId, user.name]];
            }
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[with_friends]"];
    }
    if (post.caption){[parameters setObject:post.caption
                                     forKey:@"post[message]"];}
    if (post.location){
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.latitude]
                       forKey:@"post[latitude]"];
        [parameters setObject:[NSString stringWithFormat:@"%f",post.location.coordinate.longitude]
                       forKey:@"post[longitude]"];
    }
    if (post.locationName){
        [parameters setObject:post.locationName
                       forKey:@"post[location_name]"];
    }
    if (post.FDVenueId){
        [parameters setObject:post.FDVenueId forKey:@"post[foursquareid]"];
    } else if (post.foursquareid){
        [parameters setObject:post.foursquareid forKey:@"post[foursquareid]"];
    }

    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id result) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kIsEditingPost];
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    NSURLRequest *request;
    
    if (post.photoImage) {
        NSData *imageData = UIImageJPEGRepresentation(post.photoImage, 0.5);
        request = [self multipartFormRequestWithMethod:@"PUT"
                                                  path:[NSString stringWithFormat:@"posts/%@",post.identifier]
                                            parameters:parameters
                             constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
                                 [formData appendPartWithFileData:imageData name:@"post[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                             }
                   ];
    } else {
        request = [self requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"posts/%@",post.identifier] parameters:parameters];
    }
    
    self.editPostOp = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                 success:opSuccess
                                                                 failure:opFailure];
    
    [self.editPostOp start];
    return self.editPostOp;
}

#pragma mark - Comment Methods

- (AFJSONRequestOperation *)addCommentWithBody:(NSString *)body
                                       forPost:(FDPost *)post
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:body,@"body",post.identifier,@"post_id", nil];
    return [self requestOperationWithMethod:@"POST" path:COMMENT_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
        FDPost *post = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
        success(post);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (AFJSONRequestOperation *)deleteCommentWithId:(NSNumber *)commentId
                                      forPostId:(NSNumber*)postId
                                       success:(RequestSuccess)success
                                       failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:commentId,@"id",postId,@"post_id",nil];
    return [self requestOperationWithMethod:@"DELETE" path:[NSString stringWithFormat:@"%@/%@",COMMENT_PATH,commentId] parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
        FDPost *post = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
        success(post);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}


- (AFJSONRequestOperation *)connectUser:(NSString*)name
                                  email:(NSString*)email
                               password:(NSString*)password
                                 signup:(BOOL) signup
                                   fbid:(NSString*)facebookId
                                success:(RequestSuccess)success
                                failure:(RequestFailure)failure {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (email) {
        [parameters setObject:email forKey:@"email"];
        [parameters setObject:password forKey:@"password"];
    }
    if (name) {
        [parameters setObject:name forKey:@"name"];
    }
    if (signup) [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"signup"];
        NSDictionary *rootParameters = [NSDictionary dictionaryWithObject:parameters forKey:@"user"];
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failure from user connect method: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:nil message:@"Sorry, but we're having trouble connecting to FOODIA right now. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        if (email)[[NSUserDefaults standardUserDefaults] setObject:email forKey:kUserDefaultsEmail];
        if (password)[[NSUserDefaults standardUserDefaults] setObject:password forKey:kUserDefaultsPassword];
        FDUser *user = [[FDUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        [[NSUserDefaults standardUserDefaults] setObject:user.avatarUrl forKey:kUserDefaultsAvatarUrl];
        [[NSUserDefaults standardUserDefaults] setObject:user.name forKey:kUserDefaultsUserName];
        [[NSUserDefaults standardUserDefaults] setObject:user.userId forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:user.authenticationToken forKey:kUserDefaultsAuthenticationToken];
        
        success(user);
    };
        return [self requestOperationWithMethod:@"POST"
                                           path:SESSION_PATH
                                     parameters:rootParameters
                                        success:opSuccess
                                        failure:opFailure
                ];
}

- (AFJSONRequestOperation *)forgotPassword:(NSString*)email
                                   success:(RequestSuccess)success
                                   failure:(RequestFailure)failure {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:email, @"email", nil];
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"failure from user forgot password method: %@",error.description);
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success(responseObject);
    };
    return [self requestOperationWithMethod:@"GET"
                                       path:FORGOT_PASSWORD_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure
            ];
}


#pragma mark - Like / Unlike Methods

- (AFJSONRequestOperation *)likePost:(FDPost *)post
                              detail:(BOOL)detail
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure {
    
    NSDictionary *parameters;
    if (detail){
        parameters = @{@"post_id":post.identifier,@"detail":@"true"};
    } else {
        parameters = [NSDictionary dictionaryWithObject:post.identifier forKey:@"post_id"];
    }
    return [self requestOperationWithMethod:@"POST"
                                       path:LIKE_PATH
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        FDPost *likedPost = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
                                        success(likedPost);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        failure(error);
                                    }
            ];
}

- (AFJSONRequestOperation *)unlikePost:(FDPost *)post
                                detail:(BOOL)detail
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure {
    NSDictionary *parameters;
    if (detail){
        parameters = @{@"post_id":post.identifier,@"detail":@"true"};
    } else {
        parameters = [NSDictionary dictionaryWithObject:post.identifier forKey:@"post_id"];  
    }
    return [self requestOperationWithMethod:@"DELETE"
                                       path:[NSString stringWithFormat:@"%@/%@",LIKE_PATH,post.identifier]
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                        FDPost *unlikedPost = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
                                        success(unlikedPost);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        failure(error);
                                    }
            ];
}

#pragma mark - People Methods

- (AFJSONRequestOperation *)getPeopleListSuccess:(RequestSuccess)success failure:(RequestFailure)failure {
    return [self requestOperationWithMethod:@"GET" path:PEOPLE_PATH parameters:nil success:^(AFHTTPRequestOperation *operation, id result) {
        success([self usersFromJSONArray:[result objectForKey:@"followships"]]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

#pragma mark - Recommendation Methods
//batch recommends
- (AFJSONRequestOperation *)recommendPost:(FDPost *)post onFacebook:(BOOL)facebook toRecommendees:(NSSet *)recommendees withMessage:(NSString *)message success:(RequestSuccess)success failure:(RequestFailure)failure {
    
    NSMutableArray *dict = [NSMutableArray array];
    if (facebook){
        for(FDUser *obj in [recommendees allObjects]) {
            [dict addObject:obj.facebookId];
        }
    } else {
        for(FDUser *obj in [recommendees allObjects]) {
            if (obj.userId) [dict addObject:obj.userId];
        }
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:dict,@"recommendees",post.identifier,@"identifier", message, @"message", nil];
    return [self requestOperationWithMethod:@"POST" path:RECOMMEND_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
        FDPost *post = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
        success(post);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"couldnt post the recommendation. here's why: %@", error.description);
        failure(error);
    }];
}

#pragma mark - Private Methods

// override super to add facebook ID and access token to requests
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    
    NSMutableDictionary *allParameters = [[NSMutableDictionary alloc] init];
    
    [allParameters addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"user_id", nil]];
    
    if (parameters) [allParameters addEntriesFromDictionary:parameters];
    return [super requestWithMethod:method
                               path:[[self.baseURL URLByAppendingPathComponent:path] absoluteString]
                         parameters:allParameters];
}

- (AFJSONRequestOperation *)requestOperationWithMethod:(NSString *)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters
                                               success:(OperationSuccess)success
                                               failure:(OperationFailure)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:parameters];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) {
        [request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken] forHTTPHeaderField:@"facebook_access_token"];
        [request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] forHTTPHeaderField:@"facebook_id"];
    }
    
    if (self.deviceToken) [request setValue:[NSString stringWithFormat:@"%@",self.deviceToken] forHTTPHeaderField:@"device_token"];
    
    [request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthenticationToken] forHTTPHeaderField:@"authentication_token"];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                                         success:success
                                                                                         failure:failure];
    [op start];
    return op;
}


- (NSArray *)postsFromJSONArray:(NSArray *)array {
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *postDictionary in array) {
        FDPost *post = [[FDPost alloc] initWithDictionary:postDictionary];
        [posts addObject:post];
    }
    
    return posts;
}

- (NSArray *)tagsFromJSONArray:(NSArray *)array {
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *tagDictionary in array) {
        FDFoodiaTag *tag = [[FDFoodiaTag alloc] initWithDictionary:tagDictionary];
        [tags addObject:tag];
    }
    
    return tags;
}

- (NSArray *)notificationsFromJSONArray:(NSArray *)array {
    NSMutableArray *notifications = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *notificationDictionary in array) {
        FDNotification *notification = [[FDNotification alloc] initWithDictionary:notificationDictionary];
        [notifications addObject:notification];
    }
    return notifications;
}
- (NSArray *)usersFromJSONArray:(NSArray *) array {
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *userDictionary in array) {
        FDUser *user = [[FDUser alloc] initWithDictionary:userDictionary];
        [users addObject:user];
    }
    return users;
}

- (NSArray *)objectsAsDictionaries:(NSArray *)objects {
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:objects.count];
    [objects enumerateObjectsUsingBlock:^(FDRecord *obj, NSUInteger idx, BOOL *stop) {
        [dictionaries addObject:[obj toDictionary]];
    }];
    return dictionaries;
}
            
@end
