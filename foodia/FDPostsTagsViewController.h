//
//  FDPostsTagsViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 5/22/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDFoodiaTag.h"

@interface FDPostsTagsViewController : UITableViewController
@property (nonatomic, strong) NSString *tagName;
@property (nonatomic, strong) NSMutableArray *posts;
@property BOOL universal;

@end
