//
//  FDQuickPostViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 6/9/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDFoursquareAPIClient.h"

@interface FDQuickPostViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *categoryPhrase;
@end
