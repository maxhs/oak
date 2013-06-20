//
//  FDFoodiaTagsViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 5/18/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDFoodiaTagsViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *allTags;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@end
