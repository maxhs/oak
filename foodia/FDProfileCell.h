//
//  FDProfileCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/16/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDProfileButton.h"
#import <MapKit/MapKit.h>

@interface FDProfileCell : UITableViewCell

@property (weak, nonatomic) id delegate;
@property (nonatomic, nonatomic)     IBOutlet FDProfileButton     *profileButton;
@property (nonatomic)                IBOutlet MKMapView *mapView;
@property (nonatomic,retain)         IBOutlet UILabel       *postCountLabel;
@property (nonatomic,retain)         IBOutlet UILabel       *followerCountLabel;
@property (nonatomic,retain)         IBOutlet UILabel       *followingCountLabel;
@property (nonatomic, retain) IBOutlet UIButton *postButton;
@property (nonatomic, retain) IBOutlet UIButton *followingButton;
@property (nonatomic, retain) IBOutlet UIButton *followersButton;
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

-(IBAction)makingTapped;
-(IBAction)shoppingTapped;
-(IBAction)drinkingTapped;
-(IBAction)eatingTapped;
@end
