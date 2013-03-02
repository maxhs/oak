//
//  FDFeedTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 7/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDFeedTableViewController.h"
#import "FDCache.h"
#import "Post.h"
#import "FDPostViewController.h"
#import "ECSlidingViewController.h"
#import "Utilities.h"
#import "FDAPIClient.h"
#import "Facebook.h"
#import "FDAppDelegate.h"

@interface FDFeedTableViewController ()
@end

@implementation FDFeedTableViewController


-(void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePostNotification:)
                                                 name:@"UpdatePostNotification"
                                               object:nil];
}


/*-(void)loadFromCacheReal {
    self.isLoading = true;
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *cachedPosts = [FDCache getCachedFeedPosts];


        dispatch_async( dispatch_get_main_queue(), ^{
            if (cachedPosts != nil) {
                self.posts = cachedPosts;
                [self.tableView reloadData];
            }
            [self refresh];
            self.isLoading = false;
        });
    });
}
- (void)loadFromCache {
    [self loadFromCacheReal];
}*/

- (void)saveCache {
    
} 

- (void)refresh {
    /*if(!self.isLoading) {
        NSFetchRequest *req = [Post MR_requestAllSortedBy:@"epochTime" ascending:false];
        [req setFetchOffset:20];
        NSArray *posts = [Post MR_executeFetchRequest:req];
        int i;
        for(i=0;i<[posts count];i++) {
            Post *p = [posts objectAtIndex:i];
            [Utilities deleteCachedImage:[p feedImageURL]];
            [p MR_deleteEntity];
        }
         
        // if we already have some posts in the feed, get the feed since the last post
        if (self.posts.count > 0) {
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedPostsSincePost:[self.posts objectAtIndex:0] success:^(NSMutableArray *posts) {
                if([posts count] == 20) {
                    [FDCache clearPostCache];
                    self.posts = posts;
                } else {
                    self.posts = [[posts arrayByAddingObjectsFromArray:self.posts] mutableCopy];
                }
                for(int i=0;i<[posts count];i++) {
                   [FDCache cachePost:[posts objectAtIndex:i]];
                }
                [self reloadData];
                self.feedRequestOperation = nil;

            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];

            }];
            
        // otherwise, get the intial feed
        } else {*/
            [[FDAPIClient sharedClient] setFacebookID:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookID"]];
            [[FDAPIClient sharedClient] setFacebookAccessToken: FBSession.activeSession.accessToken];
            self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getInitialFeedPostsSuccess:^(NSArray *posts) {
                /*for(int i=0;i<[posts count];i++) {
                    [FDCache cachePost:[posts objectAtIndex:i]];
                }*/
                self.posts = [NSMutableArray arrayWithArray:posts];
                [self reloadData];
                self.feedRequestOperation = nil;
            } failure:^(NSError *error) {
                self.feedRequestOperation = nil;
                [self reloadData];
                NSLog(@"error: %@",error.description);
            }];
        //}
    //}
}

- (void)viewDidAppear:(BOOL)animated {
    //if([self.posts count] != 0) [self refresh];
    //else [self loadFromCache];
    [self refresh];
    //[super.tableView reloadData];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

- (void)loadAdditionalPosts {
        self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedBeforePost:self.posts.lastObject success:^(NSMutableArray *posts) {
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
}

- (void)didShowLastRow {
    if (self.feedRequestOperation == nil && self.posts.count && self.canLoadAdditionalPosts) [self loadAdditionalPosts];
}


@end
