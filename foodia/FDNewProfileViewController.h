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
@property (nonatomic, nonatomic)     IBOutlet UILabel           *userNameLabel;
@property (nonatomic, nonatomic)     IBOutlet UILabel           *locationLabel;
@property (nonatomic, nonatomic)     IBOutlet UILabel           *workLabel;
@property (nonatomic,retain)         IBOutlet UITableView       *postList;
@property (nonatomic,retain)         IBOutlet UIImageView       *profileImageView;
@property (nonatomic,retain)         NSString       *postCountLabel;
@property (nonatomic,retain)         NSString       *followerCountLabel;
@property (nonatomic,retain)         NSString       *followingCountLabel;
@property (nonatomic,retain)         IBOutlet UIView       *profileContainerView;
@property (nonatomic,retain)         IBOutlet UILabel       *inactiveLabel;
@property (nonatomic, retain)   IBOutlet UIImageView *buttonBackground;

@property (nonatomic, strong) NSString *profileIdentifier;
@property (nonatomic, retain) IBOutlet UIButton *postButton;
@property (nonatomic, retain) IBOutlet UIButton *followingButton;
@property (nonatomic, retain) IBOutlet UIButton *followersButton;
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *detailsRequestOperation;
@property                       NSInteger               currTab;
@property (nonatomic,retain)    NSMutableDictionary     *user;
@property (strong, retain)              NSMutableArray          *filteredPosts;
@property (nonatomic,retain)    NSString                *userId;
@property (nonatomic,retain)    NSString                *currButton;
@property (nonatomic,retain)    NSArray                 *followers;
@property (nonatomic,retain)    NSArray                 *following;
@property (nonatomic, retain) IBOutlet UIButton *shoppingButton;
@property (nonatomic, retain) IBOutlet UIButton *makingButton;
@property (nonatomic, retain) IBOutlet UIButton *drinkingButton;
@property (nonatomic, retain) IBOutlet UIButton *eatingButton;

//- (IBAction)back:(id)sender;
- (void)initWithUserId:(NSString *)userId;
- (IBAction)followButtonTapped;
- (IBAction)showFollowers:(id)sender;
- (IBAction)showFollowing:(id)sender;
//- (IBAction)revealMenu:(UIBarButtonItem *)sender;
- (IBAction)getFeedForEating;
- (IBAction)getFeedForDrinking;
- (IBAction)getFeedForMaking;
- (IBAction)getFeedForShopping;
- (IBAction)activateSearch;
- (IBAction)showMapView;

@end
