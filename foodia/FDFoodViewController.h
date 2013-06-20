//
//  FDFoodViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 5/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDAppDelegate.h"
#import "FDMenuViewController.h"
#import "FDSlidingViewController.h"

@interface FDFoodViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *timePeriod;
@property (strong, nonatomic) NSString *categoryName;
- (IBAction)revealMenu:(UIBarButtonItem *)sender;
@end
