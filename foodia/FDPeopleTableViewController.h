//
//  FDPeopleTableViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/11/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDUserCell.h"
#import "FDAppDelegate.h"

@interface FDPeopleTableViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray *people;
@property (nonatomic, strong) NSMutableArray *filteredPeople;
@property (nonatomic) Boolean stillRunning;
@property (weak,nonatomic) id delegate;
- (id)initWithDelegate:(id)delegate;
@end
