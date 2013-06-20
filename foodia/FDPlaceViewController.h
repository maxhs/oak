//
//  FDPlaceViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 11/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDVenue.h"

@interface FDPlaceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>
@property (strong, nonatomic) NSString *venueId;
@property (nonatomic, strong) NSString *postIdentifier;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UILabel *totalCheckinsLabel;
@property (weak, nonatomic) IBOutlet UILabel *foodiaPosts;
@property (weak, nonatomic) IBOutlet UIButton    *menuLink;
@property (weak, nonatomic) IBOutlet UIButton    *reservationsLink;
@property (retain, nonatomic) IBOutlet UITableView *postsContainerTableView;
-(IBAction)getReservation:(id)sender;

@end
