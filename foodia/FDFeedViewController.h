//
//  FDFeedViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDClipView.h"
@interface FDFeedViewController : UIViewController {
	IBOutlet UIScrollView	*_scrollView;
    IBOutlet UIView *clipView;
}
@property (nonatomic, weak) IBOutlet UIImageView *clipViewBackground;
@property (weak, nonatomic) IBOutlet UIView             *feedContainerView;
@property (strong, nonatomic) UISearchDisplayController *searchDisplay;
@property (strong, nonatomic) UISearchBar *searchBar;

- (void)showFeed;
- (void)showFeatured;
- (void)showNearby;
- (void)showRecommended;
- (void)showProfile;
- (void)hideSlider;
//- (void)activateSearch;
- (NSString *)searchText;
@end
