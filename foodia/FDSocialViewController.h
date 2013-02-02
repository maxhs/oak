//
//  FDSocialViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDPeopleTableViewController.h"
#import "FDAPIClient.h"

@interface FDSocialViewController : FDPeopleTableViewController
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
//@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;
@end
