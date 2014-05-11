//
//  FDMenuViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "AFNetworking.h"

@interface FDMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *notifications;
@property (nonatomic,strong) AFJSONRequestOperation *feedRequestOperation;
- (void)refresh;
- (void)grow;
- (void)shrink;
@end
