//
//  FDFeaturedGridViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 8/23/12.
//  Copyright (c) FOODIA, Inc. All rights reserved.
//

#import "FDFeaturedGridViewController.h"
#import "FDCache.h"
#import <QuartzCore/QuartzCore.h>
#import "FDAppDelegate.h"

@interface FDFeaturedGridViewController ()

@end

@implementation FDFeaturedGridViewController

- (void)loadFromCache {
    NSMutableArray *cachedPosts = [FDCache getCachedFeaturedPosts];
    if (cachedPosts == nil) {
        [self refresh];
    } else {
        self.posts = cachedPosts;
        [self reloadData];
        if ([FDCache isFeaturedPostCacheStale])
            [self refresh];
    }
}

- (void)saveCache {
    [FDCache cacheFeaturedPosts:self.posts];
}

- (void)refresh {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [TestFlight passCheckpoint:@"Viewing Featured Grid View"];
    // if we already have some posts in the feed, get the feed since the last post
    if (self.posts.count) {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeaturedPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *newPosts) {
            if(self.posts != nil) {
                self.posts = [[newPosts arrayByAddingObjectsFromArray:self.posts] mutableCopy];
            }
            [self reloadData];
            self.feedRequestOperation = nil;
            
        } failure:^(NSError *error) {
            NSLog(@"Failure...");
            self.feedRequestOperation = nil;
            
        }];
        
        // otherwise, get the intial feed
    } else {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeaturedPostsSuccess:^(NSMutableArray *posts) {
            
            self.posts = posts;
        
            [self reloadData];
            self.feedRequestOperation = nil;
            
        } failure:^(NSError *error) {
            self.feedRequestOperation = nil;
            [self reloadData];
            
        }];
    }

    [self.feedRequestOperation start];
}

/*- (void)loadAdditionalPosts {
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeaturedPostsBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
        if (posts.count == 0) {
            self.canLoadAdditionalPosts = NO;
        } else {
            [self.posts addObjectsFromArray:posts];
            NSMutableArray *indexPathsForAddedPosts = [NSMutableArray arrayWithCapacity:self.posts.count];
            for (FDPost *post in posts) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0];
                [indexPathsForAddedPosts addObject:path];
            }
            [self.tableView insertRowsAtIndexPaths:indexPathsForAddedPosts
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self reloadData];
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self reloadData];
    }];
    
    [self.feedRequestOperation start];
}*/




@end
