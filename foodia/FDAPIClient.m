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
#import "FDUser.h"
#import "FDPost.h"
#import "FDNotification.h"
#import <CoreLocation/CoreLocation.h>
#import "Post.h"
#import "FDVenueLocation.h"
#import "FDCache.h"
#import "FDAppDelegate.h"


#define BASE_URL @"http://posts.foodia.com/api/v3"
#define CONNECTIVITY_PATH @"apn_registrations"
#define REGISTER_PATH @"register"
#define FEED_PATH @"posts.json"
#define FEATURED_PATH @"posts/featured.json"
#define PROFILE_PATH @"user.json"
#define RECOMMENDED_PATH @"posts/recommended.json"
#define ACTIVITY_PATH @"user_notifications.json"
#define ACTIVITY_COUNT_PATH @"new_notifications.json"
#define CATEGORY_IMAGE_PATH @"category_images.json"
#define OBJECT_SEARCH_PATH @"foodia_objects.json"
#define POST_SUBMISSION_PATH @"posts"
#define POST_UPDATE_PATH @"posts"
#define LIKE_PATH @"likes"
#define COMMENT_PATH @"comments"
#define MAP_PATH @"posts/map.json"
#define PLACES_PATH @"posts/places.json"
#define PEOPLE_PATH @"follows"
#define RECOMMEND_PATH @"recommendations"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);

@interface FDAPIClient ()

@end

@implementation FDAPIClient

@synthesize facebookID, facebookAccessToken, deviceToken, email, password;

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

/*- (AFJSONRequestOperation *)checkConnectivitySuccess:(RequestSuccess)success
                                             failure:(RequestFailure)failure
{
OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
    failure(error);
};

OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
    success(responseObject);
};
return [self requestOperationWithMethod:@"GET"
                                   path:CONNECTIVITY_PATH
                             parameters:nil
                                success:opSuccess
                                failure:opFailure];
}*/
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



// Profile Details

- (AFJSONRequestOperation *)getProfileDetails:(NSString *)uid
                                      success:(RequestSuccess)success
                                      failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"user_id", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
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


// Profile feed (i.e. feed with only posts by the user)

- (AFHTTPRequestOperation *)getFeedForProfile:(NSString *)uid
                                          success:(RequestSuccess)success
                                          failure:(RequestFailure)failure
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:uid,@"for_profile", nil];
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
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


- (AFHTTPRequestOperation *)getProfileFeedBefore:(FDPost *)beforePost
                                      forProfile:(NSString *)uid
                                         success:(RequestSuccess)success
                                         failure:(RequestFailure)failure
{
    NSString *moreProfile = [NSString stringWithFormat:@"%@,%@", uid, beforePost.epochTime];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:moreProfile,@"for_more_profile", nil];
    
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

- (AFHTTPRequestOperation *)getProfileFeedForCategory:(NSString *)category
                                           forProfile:(NSString *)uid
                                              success:(RequestSuccess)success
                                              failure:(RequestFailure)failure {
    NSString *categoryForProfile = [NSString stringWithFormat:@"%@,%@", uid, category];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:categoryForProfile,@"category_name",nil];
    
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

#pragma mark - recommended Post Methods

- (AFHTTPRequestOperation *)getRecommendedPostsSuccess:(RequestSuccess)success
                                               failure:(RequestFailure)failure
{
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self postsFromJSONArray:[responseObject objectForKey:@"posts"]]);
    };
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:RECOMMENDED_PATH
                                 parameters:nil
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
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        //[(FDAppDelegate *) [UIApplication sharedApplication].delegate setupNoConnection];
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        FDPost *post = [[FDPost alloc] initWithDictionary:[responseObject objectForKey:@"post"]];
        success(post);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:pathForPost
                                 parameters:nil
                                    success:opSuccess
                                    failure:opFailure];
}


#pragma mark - Category Image Methods

- (AFJSONRequestOperation *)getCategoryImageURLsWithSuccess:(RequestSuccess)success
                                                    failure:(RequestFailure)failure {
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        failure(error);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        success([responseObject objectForKey:@"imageURLs"]);
    };
    
    return [self requestOperationWithMethod:@"GET"
                                       path:CATEGORY_IMAGE_PATH
                                 parameters:nil
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

/*#pragma mark - Nearby Posts

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
                                       path:NEARBY_PATH
                                 parameters:parameters
                                    success:opSuccess
                                    failure:opFailure];
}*/

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
    
    
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"post[posted_at]",post.foodiaObject,@"post[object_string]",post.category,@"post[category_name]",self.facebookID,@"facebook_id",self.facebookAccessToken,@"facebook_access_token", nil];
    /*
    NSMutableDictionary * parameters = [@{
    @"post[posted_at]"              : [NSDate date],
    @"post[object_string]"          : post.foodiaObject,
    @"post[category_name]"          : post.category,
    @"facebook_id"                  : self.facebookID,
    @"facebook_access_token"        : self.facebookAccessToken
    } mutableCopy];
    */
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenGraph"]) {
        NSLog(@"should be sharing via OG");
        [parameters setObject:post.foodiaObject
                       forKey:@"post[og]"];
    }
    if (post.withFriends) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.withFriends.count];
        for (FDUser *user in post.withFriends) {
            [mutableArray addObject:[NSString stringWithFormat:@"%@|%@", user.facebookId, user.name]];
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[with_friends]"];
    }
    if (post.recommendedTo) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.recommendedTo.count];
        for (FDUser *user in post.recommendedTo) {
            [mutableArray addObject:[NSString stringWithFormat:@"%@|%@", user.facebookId, user.name]];
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[recommend_friends]"];
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
    }
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id result) {
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    NSURLRequest *request;
    
    if (post.photoImage) {
    NSData *imageData = UIImageJPEGRepresentation(post.photoImage, 1.0);
    request = [self multipartFormRequestWithMethod:@"POST"
                                                            path:POST_SUBMISSION_PATH
                                                      parameters:parameters
                                       constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
                                           [formData appendPartWithFileData:imageData name:@"post[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                                       }
                             ];
    } else {
        request = [self requestWithMethod:@"POST" path:POST_SUBMISSION_PATH parameters:parameters];
    }
    
    AFJSONRequestOperation *op;
    
    op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
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
        NSLog(@"result from delete post method");
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
    
    
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"post[posted_at]",post.foodiaObject,@"post[object_string]",post.category,@"post[category_name]",post.identifier, @"post[identifier]",self.facebookID,@"facebook_id",self.facebookAccessToken,@"facebook_access_token", nil];
    if (post.withFriends) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.withFriends.count];
        for (FDUser *user in post.withFriends) {
            [mutableArray addObject:[NSString stringWithFormat:@"%@|%@", user.facebookId, user.name]];
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[with_friends]"];
    }
    /*if (post.recommendedTo) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:post.recommendedTo.count];
        for (FDUser *user in post.recommendedTo) {
            [mutableArray addObject:[NSString stringWithFormat:@"%@|%@", user.facebookId, user.name]];
        }
        [parameters setObject:[mutableArray componentsJoinedByString:@","]
                       forKey:@"post[recommend_friends]"];
    }*/
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
        success(result);
    };
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    };
    NSURLRequest *request;
    
    if (post.photoImage) {
        NSData *imageData = UIImageJPEGRepresentation(post.photoImage, 1.0);
        request = [self multipartFormRequestWithMethod:@"PUT"
                                                  path:[NSString stringWithFormat:@"posts/%@",post.identifier]
                                            parameters:parameters
                             constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
                                 [formData appendPartWithFileData:imageData name:@"post[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                             }
                   ];
    } else {
        request = [self requestWithMethod:@"POST" path:[NSString stringWithFormat:@"posts/%@",post.identifier] parameters:parameters];
    }
    
    AFJSONRequestOperation *op;
    
    op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                 success:opSuccess
                                                                 failure:opFailure];
    
    [op start];
    
    return op;
}

#pragma mark - Comment Methods

- (AFJSONRequestOperation *)addCommentWithBody:(NSString *)body
                               forPost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:body,@"body",post.identifier,@"post_id", nil];
    return [self requestOperationWithMethod:@"POST" path:COMMENT_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
        FDPost *post = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPostUpdated object:post];
        success(post);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}


- (AFJSONRequestOperation *)registerUser {
    if (self.facebookAccessToken && self.facebookID){
    return [self requestOperationWithMethod:@"POST"
                                       path:REGISTER_PATH
                                 parameters:[NSDictionary dictionaryWithObjectsAndKeys:self.facebookAccessToken,@"access_token",self.facebookID,@"facebook_id", nil]
                                    success:^(AFHTTPRequestOperation *operation, id result) {
                                    
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        NSLog(@"Register Failed. %@ ... %@",operation.responseString, error.description);
                                    }
            ];
    } else {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.email, @"email", self.password, @"password", nil];
        NSDictionary *rootParameters = [NSDictionary dictionaryWithObject:parameters forKey:@"user"];
        return [self requestOperationWithMethod:@"POST"
                                           path:REGISTER_PATH
                                     parameters:rootParameters
                                        success:^(AFHTTPRequestOperation *operation, id result) {
                                            NSLog(@"result from register email method: %@",result);
                                        }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            NSLog(@"Register Failed. %@ ... %@",operation.responseString, error.description);
                                        }
                ];
    }
}


#pragma mark - Like / Unlike Methods

- (AFJSONRequestOperation *)likePost:(FDPost *)post
                             success:(RequestSuccess)success
                             failure:(RequestFailure)failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:post.identifier forKey:@"post_id"];
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
                               success:(RequestSuccess)success
                               failure:(RequestFailure)failure {
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:post.identifier forKey:@"post_id"];
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
        success([self usersFromJSONArray:result]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

#pragma mark - Recommendation Methods

- (AFJSONRequestOperation *)recommendPost:(FDPost *)post toRecommendees:(NSSet *)recommendes withMessage:(NSString *)message success:(RequestSuccess)success failure:(RequestFailure)failure {
    NSMutableArray *dict = [NSMutableArray array];
    for(FDUser *obj in [recommendes allObjects]) {
        [dict addObject:obj.facebookId];
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:dict,@"recommendees",post.identifier,@"post_id", message, @"message", nil];
    return [self requestOperationWithMethod:@"POST" path:RECOMMEND_PATH parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
        FDPost *post = [[FDPost alloc] initWithDictionary:[result objectForKey:@"post"]];
        success(post);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"couldnt post. here's why: %@", error.description);
    }];
}

#pragma mark - Private Methods

// override super to add facebook ID and access token to requests
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    
    NSMutableDictionary *allParameters = [[NSMutableDictionary alloc] init];
    if (self.facebookID && self.facebookAccessToken) {
        [allParameters addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:self.facebookAccessToken,@"facebook_access_token",self.facebookID,@"facebook_id",self.deviceToken,@"device_token", nil]];
    }

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
