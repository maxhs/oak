//
//  FDPostTableViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/21/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAPIClient.h"
#import "FDPost.h"
#import "EGORefreshTableHeaderView.h"
#import "FDVenue.h"

@interface FDPostTableViewController : UITableViewController <EGORefreshTableHeaderDelegate, UIScrollViewDelegate>
@property (nonatomic,strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (weak,nonatomic) id delegate;
@property (nonatomic,strong) NSMutableArray *posts;
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic) BOOL canLoadAdditionalPosts;
@property (nonatomic) NSInteger notificationsPending;
@property (nonatomic) BOOL fewPosts;
@property (nonatomic) BOOL didLoadFromCache;
@property (nonatomic) BOOL isLoading;

- (void)reloadData;
- (void)refresh;
- (id)initWithDelegate:(id)delegate;
-(void)setIsLikedByUsers:(NSDictionary *)newLikers withLikeCount:(NSInteger)newLikeCount forPostWithId:(NSString *)postId;

@end

@class FDPost;

@protocol FDPostTableViewControllerDelegate <NSObject>
- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPost:(FDPost *)post;
- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPlace:(FDVenue *)place;
@end