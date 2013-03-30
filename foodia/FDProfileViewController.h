//
//  FDProfileViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/16/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDAPIClient.h"
#import "FDUser.h"
#import "ECSlidingViewController.h"
#import "FDPeopleTableViewController.h"
#import <MapKit/MapKit.h>
#import "FDProfileButton.h"
#import "Flurry.h"

typedef enum { kDisplayTabPosts, kDisplayTabFollowing, kDisplayTabFollowers } kDisplayTab;

@interface FDProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate> 
@property (weak, nonatomic) id delegate;
@property (nonatomic, nonatomic)     IBOutlet FDProfileButton     *profileButton;
@property (nonatomic, nonatomic)     IBOutlet UILabel           *userNameLabel;
@property (nonatomic,retain)         IBOutlet MKMapView *mapView;
@property (nonatomic,retain)         IBOutlet UITableView       *postList;

@property (nonatomic,retain)         IBOutlet UILabel       *postCountLabel;
@property (nonatomic,retain)         IBOutlet UILabel       *followerCountLabel;
@property (nonatomic,retain)         IBOutlet UILabel       *followingCountLabel;
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
@property (strong, retain)              NSMutableArray          *posts;
@property (strong, retain)              NSMutableArray          *filteredPosts;
@property (nonatomic,retain)    NSString                *userId;
@property (nonatomic,retain)    NSString                *currButton;
@property (nonatomic,retain)    NSArray                 *followers;
@property (nonatomic,retain)    NSArray                 *following;
@property (nonatomic, retain) IBOutlet UIButton *shoppingButton;
@property (nonatomic, retain) IBOutlet UIButton *makingButton;
@property (nonatomic, retain) IBOutlet UIButton *drinkingButton;
@property (nonatomic, retain) IBOutlet UIButton *eatingButton;
@property (nonatomic, retain) IBOutlet UIButton *socialButton;

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
@end
