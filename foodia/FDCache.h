//
//  FDCache.h
//  foodia
//
//  Created by Max Haines-Stiles on 2/2/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FDPost;

@interface FDCache : NSObject
+ (NSMutableArray*)getCachedRankedPosts;
+ (NSMutableArray*)getCachedFeaturedPosts;
+ (NSMutableArray*)getCachedFeedPosts;
+ (NSDictionary *)getCachedCategoryImageURLs;
+ (FDPost *)getCachedPostForIdentifier:(NSString *)identifier;

+ (void)cachePost:(FDPost *)postToCache;
+ (void)clearPostCache;

+ (void)cacheCategoryImageURLs:(NSDictionary *)URLs;
//+ (void)cacheFeedPosts:(NSMutableArray*)posts;
+ (void)cacheFeaturedPosts:(NSMutableArray*)posts;
+ (void)cacheRankedPosts:(NSMutableArray*)posts;
+ (void)cacheDetailPost:(FDPost *)post;

+ (BOOL)isRankedPostCacheStale;
+ (BOOL)isFeaturedPostCacheStale;
+ (BOOL)isFeedPostCacheStale;
+ (BOOL)isCategoryImageCacheStale;


+ (void)cacheNearbyPosts:(NSMutableArray*)posts;
+ (NSMutableArray*)getCachedNearbyPosts;
+ (BOOL)isNearbyPostsCacheStale;

+ (void)cacheRecommendedPosts:(NSMutableArray*)posts;
+ (NSMutableArray*)getCachedRecommendedPosts;
+ (BOOL)isRecommendedPostCacheStale;

+ (void)cachePeople:(NSArray *)people;
+ (NSArray *)getCachedPeople;
+ (BOOL)isPeopleCacheStale;

+ (void)clearCache;
@end
