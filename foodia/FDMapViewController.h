//
//  FDMapViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 11/3/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDVenue.h"

@interface FDMapViewController : UIViewController
@property (strong, nonatomic) FDVenue *place;
@property (strong, nonatomic) NSString *venueId;
@property (nonatomic, strong) NSString *postIdentifier;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalCheckinsLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (weak, nonatomic) IBOutlet UIButton    *menuLink;
@property (weak, nonatomic) IBOutlet UIButton    *reservationsLink;
@property (weak, nonatomic) IBOutlet UITextView    *tipsTextView;
@property (weak, nonatomic) IBOutlet UITextField *sunday;
@property (weak, nonatomic) IBOutlet UITextField *monday;
@property (weak, nonatomic) IBOutlet UITextField *tuesday;
@property (weak, nonatomic) IBOutlet UITableView *postsContainerTableView;

@end
