//
//  FDFeedViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDClipView.h"
//#import "GAITrackedViewController.h"

@interface FDFeedViewController : UIViewController @property (weak, nonatomic) IBOutlet UIView             *feedContainerView;
@property (strong, nonatomic) UISearchDisplayController *searchDisplay;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (nonatomic, assign) int lastContentOffsetX;
@property (nonatomic, assign) int lastContentOffsetY;
@property BOOL goToComment;
@property (nonatomic, strong) NSMutableArray *swipedCells;

- (IBAction)rightBarButtonAction;
@end
