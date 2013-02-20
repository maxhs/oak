//
//  FDPlacesViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/19/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPostTableViewController.h"
#import "FDAppDelegate.h"
typedef void (^TaskCompletionBlock)(void);

@interface FDPlacesViewController : FDPostTableViewController
@property (nonatomic, copy) TaskCompletionBlock block;
@end
