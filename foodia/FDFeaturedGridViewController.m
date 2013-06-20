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
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [Flurry logPageView];
}

- (void)loadFromCache {
    NSMutableArray *cachedPosts = [FDCache getCachedFeaturedPosts];
    NSLog(@"cached posts? %@",cachedPosts);
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

- (void)loadFresh {
    
}

- (void)saveCache {
    [FDCache cacheFeaturedPosts:self.posts];
}


-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        //NSLog(@"should be saving the cache");
        //[self saveCache];
    }
}

- (void)refresh {
    [Flurry logEvent:@"Viewing featured grid" timed:YES];
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
