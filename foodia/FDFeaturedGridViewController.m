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
#import "Flurry.h"

@interface FDFeaturedGridViewController ()

@end

@implementation FDFeaturedGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Flurry logPageView];

}


- (void)loadFromCache {
    NSMutableArray *cachedPosts = [FDCache getCachedFeaturedPosts];
    if (cachedPosts == nil) {
        [self refresh];
    } else {
        if ([FDCache isFeaturedPostCacheStale]) [self refresh];
        else {
            self.posts = cachedPosts;
            [self reloadData];
        }
    }
}

- (void)saveCache {
    [FDCache cacheFeaturedPosts:self.posts];
}

- (void)refresh {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logEvent:@"Viewing featured grid" timed:YES];
    // if we already have some posts in the feed, get the feed since the last post
    if (self.posts.count) {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeaturedPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *newPosts) {
            if(self.posts != nil) {
                self.posts = [[newPosts arrayByAddingObjectsFromArray:self.posts] mutableCopy];
            }
            [self reloadData];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f){
                NSLog(@"ios7 device");
                [self.tableView setContentInset:UIEdgeInsetsMake(100, 0, 0, 0)];
            }
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

- (void)loadAdditionalPosts {

    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeaturedPostsBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
        if (posts.count == 0) {
            self.canLoadAdditionalPosts = NO;
        } else {
            [self.posts addObjectsFromArray:posts];
            [self reloadData];
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self reloadData];
    }];
    
    [self.feedRequestOperation start];
}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) [self loadAdditionalPosts];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.feedRequestOperation = nil;
}

@end
