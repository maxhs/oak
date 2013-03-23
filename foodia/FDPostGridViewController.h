//
//  FDPostGridViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/1/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAPIClient.h"
#import "FDPost.h"
#import "FDAppDelegate.h"

@interface FDPostGridViewController : UITableViewController
@property (weak,nonatomic) id delegate;
@property (nonatomic,strong) NSMutableArray *posts;
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic) BOOL canLoadAdditionalPosts;
@property NSMutableArray *cellPosts;
@property (nonatomic) NSInteger notificationsPending;
@property NSInteger *rows;
- (void)reloadData;
- (void)refresh;
- (id)initWithDelegate:(id)delegate;
//- (IBAction)revealMenu:(UIBarButtonItem *)sender;
//- (IBAction)revealFeedTypes:(UIBarButtonItem *)sender;
@end

@class FDPost;

@protocol FDPostGridViewControllerDelegate <NSObject>

//- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtPostsIndex:(NSUInteger *)postsIndex;
- (void)postGridViewController:(FDPostGridViewController *)controller didSelectPost:(FDPost *)post;

@end
