//
//  FDNewProfileViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/16/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPostTableViewController.h"
#import "FDProfileButton.h"

@interface FDNewProfileViewController : FDPostTableViewController

@property (weak, nonatomic) id delegate;
@property (nonatomic, nonatomic)     FDProfileButton     *profileButton;
@property (nonatomic,retain)         NSString       *postCountLabel;
@property (nonatomic,retain)         NSString       *followerCountLabel;
@property (nonatomic,retain)         NSString       *followingCountLabel;
@property (nonatomic, strong) NSString *profileIdentifier;
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *detailsRequestOperation;
@property                       NSInteger               currTab;
@property (nonatomic,retain)    NSMutableDictionary     *user;
@property (strong, retain)              NSMutableArray          *filteredPosts;
@property (nonatomic,retain)    NSString                *userId;
@property (nonatomic,retain)    NSString                *currButton;
@property (nonatomic,retain)    NSArray                 *followers;
@property (nonatomic,retain)    NSArray                 *following;

- (void)initWithUserId:(NSString *)userId;
- (IBAction)followButtonTapped;
- (IBAction)showFollowers:(id)sender;
- (IBAction)showFollowing:(id)sender;
- (void)getFeedForEating;
- (void)getFeedForDrinking;
- (void)getFeedForMaking;
- (void)getFeedForShopping;
- (IBAction)activateSearch;
//- (IBAction)showMapView;

@end
