//
//  FDCategoryPostsViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 6/5/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDPost.h"
#import "FDPostCell.h"

@interface FDCategoryPostsViewController : UIViewController
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSString *timePeriod;
@property (strong, nonatomic) NSMutableArray *posts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
