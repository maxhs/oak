//
//  FDCache.m
//  foodia
//
//  Created by Max Haines-Stiles on 2/2/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDCache.h"
#import "FDPost.h"
#import "Post.h"
#import "FDUser.h"
#import "FDAPIClient.h"

#define kMenuStaleSeconds 10
#define kCategoryImagesStaleSeconds 60
#define kPeopleStaleSeconds 120

@implementation FDCache

static NSMutableDictionary *memoryCache;
static NSMutableArray *recentlyAccessedKeys;
static int kCacheMemoryLimit;

#pragma mark - initialization


//
// 1 ensures that the cache directory exists
// clears the cache if the existing cache is from a different version of the app
// initializes the memory cache
// registers for memory/termination notifications
//
+ (void) initialize {
    
    // create the cache directory if it doesn't exist
    NSString *cacheDirectory = [FDCache cacheDirectory];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:nil];            
    }
    
    // get the app's version, compare it to the saved value, and clear the cache if necessary
    double lastSavedCacheVersion = [[NSUserDefaults standardUserDefaults] doubleForKey:@"CACHE_VERSION"];
    double currentAppVersion = [[FDCache appVersion] doubleValue];
    
    if( lastSavedCacheVersion == 0.0f || lastSavedCacheVersion < currentAppVersion)
    {
        // clear the cache, because the last version is old (or wasn't there)
        [FDCache clearCache];
        
        // assigning current version to preference
        [[NSUserDefaults standardUserDefaults] setDouble:currentAppVersion forKey:@"CACHE_VERSION"];					
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // set up the memory cache
    memoryCache = [[NSMutableDictionary alloc] init];
    recentlyAccessedKeys = [[NSMutableArray alloc] init];
    
    // you can set this based on the running device and expected cache size
    kCacheMemoryLimit = 10;
    
    // register for notifications so we know when to save the memory cache
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveMemoryCacheToDisk:) 
                                                 name:UIApplicationDidReceiveMemoryWarningNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveMemoryCacheToDisk:) 
                                                 name:UIApplicationDidEnterBackgroundNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveMemoryCacheToDisk:) 
                                                 name:UIApplicationWillTerminateNotification 
                                               object:nil];  
}

//
// Is this method for real? Don't think so.
//
- (void) dealloc {
    
    memoryCache = nil;
    
    recentlyAccessedKeys = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
}

#pragma mark - generic caching tasks

+ (void) saveMemoryCacheToDisk:(NSNotification *)notification {
    for(NSString *filename in [memoryCache allKeys])
    {
        NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:filename];  
        NSData *cacheData = [memoryCache objectForKey:filename];
        [cacheData writeToFile:archivePath atomically:YES];
    }
    
    [memoryCache removeAllObjects];  
}

+ (void)clearCache {
    NSArray *cachedItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FDCache cacheDirectory] 
                                                                               error:nil];
    
    for(NSString *path in cachedItems)
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    [memoryCache removeAllObjects];
}
+ (void)clearPostCache {
    [Post MR_truncateAll];
}

+ (NSString*) appVersion {
	CFStringRef versStr = (CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
	NSString *version = [NSString stringWithUTF8String:CFStringGetCStringPtr(versStr,kCFStringEncodingMacRoman)];
	
	return version;
}

+ (NSString*) cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
	return [cachesDirectory stringByAppendingPathComponent:@"FDCache"];  
}

+ (void)cacheData:(NSData*)data toFile:(NSString*)fileName {
    [memoryCache setObject:data forKey:fileName];
    if([recentlyAccessedKeys containsObject:fileName])
    {
        [recentlyAccessedKeys removeObject:fileName];
    }
    
    [recentlyAccessedKeys insertObject:fileName atIndex:0];
    
    if([recentlyAccessedKeys count] > kCacheMemoryLimit)
    {
        NSString *leastRecentlyUsedDataFilename = [recentlyAccessedKeys lastObject];
        NSData *leastRecentlyUsedCacheData = [memoryCache objectForKey:leastRecentlyUsedDataFilename];
        NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:fileName];
        [leastRecentlyUsedCacheData writeToFile:archivePath atomically:YES];
        
        [recentlyAccessedKeys removeLastObject];
        [memoryCache removeObjectForKey:leastRecentlyUsedDataFilename];
    }
}

+ (NSData*)dataForFile:(NSString*)fileName {
    NSData *data = [memoryCache objectForKey:fileName];
    if(data) return data; // data is present in memory cache
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:fileName];
    data = [NSData dataWithContentsOfFile:archivePath];
    
    if(data)
        [self cacheData:data toFile:fileName]; // put the recently accessed data to memory cache
    
    return data;
}

#pragma mark - Feed Caching Methods


+ (FDPost *)FDPostFromPost:(Post *)postFrom {
    FDPost *ret = [FDPost alloc];
    ret.foodiaObject        = postFrom.caption;
    ret.category            = postFrom.category;
    ret.feedImageUrlString  =   postFrom.feedImageURL;
    ret.epochTime           = postFrom.epochTime;
    ret.comments            = [NSSet set];//[[NSString alloc] initWithData:[NSJSONSerialization
    //                                dataWithJSONObject:[postToCache.comments allObjects] options:0 error:&error] encoding:NSUTF8StringEncoding];
    ret.detailImageUrlString      = postFrom.detailImageURL;
    ret.featured            = postFrom.featured;
    ret.featuredEpochTime   = postFrom.featuredEpochTime;
    ret.identifier          = [postFrom.postId stringValue];
    ret.latitude            = [NSNumber numberWithInteger:[postFrom.latitude integerValue]];
    ret.likeCount           = [NSNumber numberWithInteger:[postFrom.likeCount integerValue]];//@TODO
    NSError *error = nil;
    ret.likers              = [NSJSONSerialization JSONObjectWithData:[postFrom.likers dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    ret.foursquareid          = [postFrom.foursquareid stringValue];
    ret.locationName        = postFrom.locationName;
    ret.longitude           = [NSNumber numberWithInteger:[postFrom.longitude integerValue]];
    ret.photoImage          = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:postFrom.photoImage]]];
    
    
    
    
    //NSArray *recommendedArr = [NSJSONSerialization JSONObjectWithData:[postFrom.withFriends dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    
    ret.isRecommendedToUser = 0;
    
    NSMutableArray *newRecommendedArr = [NSMutableArray array];
    /*for(id friend in recommendedArr) {
        NSData *d = [NSData dat DataFromString:friend];
        FDUser *recTo = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        if([recTo.facebookId isEqualToString:[FDAPIClient sharedClient].facebookID]) ret.isRecommendedToUser = [NSNumber numberWithInt:1];
        [newRecommendedArr addObject:recTo];
    }*/
    ret.recommendedTo = [NSSet setWithArray:newRecommendedArr];
    
    ret.recommendedEpochTime = 0;
    
    ret.recCount            = [NSNumber numberWithInt:[ret.recommendedTo count]];
    //ret.user              = (FDUser *)[NSKeyedUnarchiver unarchiveObjectWithData:[APBase64Converter base64DataFromString:postFrom.userId]];
    
    
    
    
    //NSArray *friendsArr = [NSJSONSerialization JSONObjectWithData:[postFrom.withFriends dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    
    NSMutableArray *newFriendsArr = [NSMutableArray array];
    /*for(id friend in friendsArr) {
        NSData *d = [APBase64Converter base64DataFromString:friend];
        FDUser *theFriend = [NSKeyedUnarchiver unarchiveObjectWithData:d];
        [newFriendsArr addObject:theFriend];
    }*/
    ret.withFriends = [NSSet setWithArray:newFriendsArr];

    
    ret.customVenue         = false;
    return ret;
}

+ (void)cachePost:(FDPost *)postToCache {
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_contextForCurrentThread];

    NSArray *posts = [Post MR_findByAttribute:@"postId" withValue:postToCache.identifier inContext:localContext];
    
    if([posts count] == 1) {
        Post *p = [Post MR_findFirstByAttribute:@"postId" withValue:postToCache.identifier inContext:localContext];
        [p MR_deleteEntity];
        [localContext MR_save];
    }
    NSError *error;
    if (postToCache != nil) {
        Post *postCaching               = [Post MR_createInContext:localContext];
        postCaching.caption             = postToCache.foodiaObject;
        postCaching.category            = postToCache.category;
        postCaching.comments            = @"";//[[NSString alloc] initWithData:[NSJSONSerialization
        //                                dataWithJSONObject:[postToCache.comments allObjects] options:0 error:&error] encoding:NSUTF8StringEncoding];
        postCaching.detailImageURL      = postToCache.detailImageUrlString;
        postCaching.epochTime           = [NSNumber numberWithUnsignedInt:[postToCache.epochTime intValue]];
        postCaching.featured            = postToCache.featured;
        postCaching.featuredEpochTime   = [[NSNumberFormatter alloc] numberFromString:[NSString stringWithFormat:@"%@", postToCache.featuredEpochTime]];
        postCaching.feedImageURL        = postToCache.feedImageUrlString;
        postCaching.postId              = [NSNumber numberWithUnsignedInt:[postToCache.identifier intValue]];
        postCaching.latitude            = @"0";//@TODO[postToCache.latitude stringValue];
        postCaching.likeCount           = [postToCache.likeCount stringValue];
        postCaching.likers              = [[NSString alloc] initWithData:[NSJSONSerialization
                                                                          dataWithJSONObject:postToCache.likers options:0 error:&error] encoding:NSUTF8StringEncoding];
        postCaching.foursquareid          = [NSNumber numberWithInteger:[postToCache.foursquareid
                                                                       integerValue]];
        postCaching.locationName        = postToCache.locationName;
        postCaching.longitude           = @"0";//@TODO[postToCache.longitude stringValue];
        postCaching.photoImage          = postToCache.detailImageUrlString;
        
        
        NSMutableArray *recommendedTo = [NSMutableArray array];
        /*for(id friend in postToCache.recommendedTo) {
            [recommendedTo addObject:[NSString stringWithFormat:@"%@",
                                    [APBase64Converter base64forData:[NSKeyedArchiver archivedDataWithRootObject:friend]]]];
        }*/
        postCaching.recommendedTo         = [[NSString alloc] initWithData:[NSJSONSerialization
                                                                          dataWithJSONObject:recommendedTo
                                                                          options:0 error:&error] encoding:NSUTF8StringEncoding];

        
        postCaching.recommendedTo       = @"";//[[NSString alloc] initWithData:[NSJSONSerialization
        //                                dataWithJSONObject:[postToCache.recommendedTo allObjects] options:0 error:&error] encoding:NSUTF8StringEncoding];
        //postCaching.userId              = [NSString stringWithFormat:@"%@",[APBase64Converter base64forData:[NSKeyedArchiver archivedDataWithRootObject:postToCache.user]]];
        
        
        NSMutableArray *withFriends = [NSMutableArray array];
        for(id friend in postToCache.withFriends) {
            //[withFriends addObject:[NSString stringWithFormat:@"%@",
            //                         [APBase64Converter base64forData:[NSKeyedArchiver archivedDataWithRootObject:friend]]]];
        }
        postCaching.withFriends         = [[NSString alloc] initWithData:[NSJSONSerialization
                                                                          dataWithJSONObject:withFriends
                                                                          options:0 error:&error] encoding:NSUTF8StringEncoding];
        [localContext MR_save];
    }
}



+ (NSMutableArray*)getCachedFeedPosts {
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_contextForCurrentThread];

    NSFetchRequest *postsReq = [Post MR_requestAllSortedBy:@"epochTime" ascending:false inContext:localContext];
    [postsReq setFetchLimit:25];
    NSArray *posts = [Post MR_executeFetchRequest:postsReq];
    NSMutableArray *postsReturn = [NSMutableArray array];
    for (id post in posts) {
        FDPost *p = [self FDPostFromPost:post];
        if(p != nil)
          [postsReturn addObject:p];
    }
    return postsReturn;
    //return nil;
}

+ (BOOL)isFeedPostCacheStale {
    // if it is in memory cache, it is not stale
    if([recentlyAccessedKeys containsObject:@"Feed.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"Feed.archive"];  
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kMenuStaleSeconds;
}

#pragma mark -Ranked posts caching methods


+ (void)cacheRankedPosts:(NSMutableArray*)posts {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:posts]
             toFile:@"Ranked.archive"];
}

+ (NSMutableArray*)getCachedRankedPosts {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"Ranked.archive"]];
}

+ (BOOL)isRankedPostCacheStale {
    // if it is in memory cache, it is not stale
    if([recentlyAccessedKeys containsObject:@"Ranked.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"Featured.archive"];
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kMenuStaleSeconds;
}

#pragma mark - Featured Posts Caching Methods

+ (void)cacheFeaturedPosts:(NSMutableArray*)posts {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:posts]
             toFile:@"Featured.archive"];  
}

+ (NSMutableArray*)getCachedFeaturedPosts {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"Featured.archive"]];
}

+ (BOOL)isFeaturedPostCacheStale {
    // if it is in memory cache, it is not stale
    if([recentlyAccessedKeys containsObject:@"Featured.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"Featured.archive"];  
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kMenuStaleSeconds;
}

#pragma mark - Nearby Posts Caching Methods

+ (void)cacheNearbyPosts:(NSMutableArray*)posts {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:posts]
             toFile:@"Nearby.archive"];
}

+ (NSMutableArray*)getCachedNearbyPosts {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"Nearby.archive"]];
}

+ (BOOL)isNearbyPostsCacheStale {
    // if it is in memory cache, it is not stale
    if([recentlyAccessedKeys containsObject:@"Nearby.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"Nearby.archive"];
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kMenuStaleSeconds;
}

#pragma mark - Recommended Posts Caching Methods

+ (void)cacheRecommendedPosts:(NSMutableArray*)posts {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:posts]
             toFile:@"Recommended.archive"];
}

+ (NSMutableArray*)getCachedRecommendedPosts {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"Recommended.archive"]];
}

+ (BOOL)isRecommendedPostCacheStale {
    // if it is in memory cache, it is not stale
    if([recentlyAccessedKeys containsObject:@"Recommended.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"Recommended.archive"];
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kMenuStaleSeconds;
}

#pragma mark - Post Detail Cache Methods

+ (NSString *)archiveFileNameForPostIdentifier:(NSString *)identifier {
    return [NSString stringWithFormat:@"Post%@.archive", identifier];
}

+ (void)cacheDetailPost:(FDPost *)post {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:post] 
             toFile:[FDCache archiveFileNameForPostIdentifier:post.identifier]];
}

+ (FDPost *)getCachedPostForIdentifier:(NSString *)identifier {
    NSData *postData = [FDCache dataForFile:[FDCache archiveFileNameForPostIdentifier:identifier]];
    return [NSKeyedUnarchiver unarchiveObjectWithData:postData];
}

#pragma mark - Category Image Methods

+ (void)cacheCategoryImageURLs:(NSDictionary *)URLs {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:URLs]
             toFile:@"CategoryImages.archive"];
}

+ (NSArray *)getCachedCategoryImageURLs {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"CategoryImages.archive"]];
}

+ (BOOL)isCategoryImageCacheStale {
    if([recentlyAccessedKeys containsObject:@"CategoryImages.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"CategoryImages.archive"];
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kCategoryImagesStaleSeconds;
}


#pragma mark - People Cache Methods

+ (void)cachePeople:(NSArray *)people {
    [self cacheData:[NSKeyedArchiver archivedDataWithRootObject:people]
             toFile:@"People.archive"];
}

+ (NSArray *)getCachedPeople {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForFile:@"People.archive"]];
}

+ (BOOL)isPeopleCacheStale {
    if ([recentlyAccessedKeys containsObject:@"People.archive"])
        return NO;
    
	NSString *archivePath = [[FDCache cacheDirectory] stringByAppendingPathComponent:@"People.archive"];
    
    NSTimeInterval stalenessLevel = [[[[NSFileManager defaultManager] attributesOfItemAtPath:archivePath error:nil] fileModificationDate] timeIntervalSinceNow];
    
    return stalenessLevel > kPeopleStaleSeconds;
}

@end
