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
#import "Flurry.h"

typedef enum { kDisplayTabPosts, kDisplayTabFollowing, kDisplayTabFollowers } kDisplayTab;

@interface FDProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
    NSMutableArray          *filteredPosts;
}
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *detailsRequestOperation;                   
@property (strong, strong)              NSMutableArray          *posts;
@property (nonatomic,strong)    NSString                *userId;
@property (nonatomic, strong)   NSMutableArray *swipedCells;
@property (nonatomic, strong) NSString *profileIdentifier;

- (void)initWithUserId:(NSString *)userId;
- (IBAction)followButtonTapped;
- (IBAction)showFollowers:(id)sender;
- (IBAction)showFollowing:(id)sender;
- (IBAction)activateSearch;
@end
