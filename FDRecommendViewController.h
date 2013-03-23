//
//  FDRecommendViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPeopleTableViewController.h"
@class FDPost;
@interface FDRecommendViewController : FDPeopleTableViewController
@property (nonatomic, retain) FDPost *post;
@property BOOL postingToFacebook;
@end
