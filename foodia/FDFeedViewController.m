//
//  FDFeedViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDFeedViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Facebook.h"
#import "FDFeaturedGridViewController.h"
#import "FDFeedTableViewController.h"
#import "FDRecommendedTableViewController.h"
#import "FDPost.h"
#import "FDNearbyTableViewController.h"
#import "FDUser.h"
#import "FDPostViewController.h"
#import "ECSlidingViewController.h"
#import "FDPlaceViewController.h"
#import "FDMenuViewController.h"
#import "FDPlacesViewController.h"
#import "FDProfileViewController.h"

@interface FDFeedViewController () <FDPostTableViewControllerDelegate, FDPostGridViewControllerDelegate, UIScrollViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic,strong) FDFeedTableViewController          *feedTableViewController;
@property (nonatomic,strong) FDFeaturedGridViewController      *featuredGridViewController;
@property (nonatomic,strong) FDPlacesViewController        *placesViewController;
@property (nonatomic,strong) FDRecommendedTableViewController   *recommendedTableViewController;
@property (nonatomic,strong) FDRecommendedTableViewController    *keepersViewController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sliderButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButtonItem;
@property (retain, nonatomic) IBOutlet UIButton *addPostButton;
@property (weak, nonatomic) IBOutlet UILabel *feedLabel;
@property (weak, nonatomic) IBOutlet UILabel *featuredLabel;
@property (weak, nonatomic) IBOutlet UILabel *myPostsLabel;
@property (weak, nonatomic) IBOutlet UILabel *keepersLabel;
@property (weak, nonatomic) IBOutlet UILabel *nearbyLabel;
@property (weak, nonatomic) IBOutlet UILabel *recLabel;
@property (nonatomic, weak) UIViewController *currentChildViewController;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property BOOL movedRight;
@property int page;

- (IBAction)revealMenu:(UIBarButtonItem *)sender;
@end

@implementation FDFeedViewController
@synthesize lastContentOffsetX = _lastContentOffsetX;
@synthesize lastContentOffsetY = _lastContentOffsetY;
@synthesize page = _page;
@synthesize documentInteractionController = _documentInteractionController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Looking at Feed View" timed:YES];

    [(FDMenuViewController*)self.slidingViewController.underLeftViewController shrink];
    
    self.feedTableViewController        = [[FDFeedTableViewController alloc]        initWithDelegate:self];
    self.featuredGridViewController    = [[FDFeaturedGridViewController alloc]    initWithDelegate:self];
    //self.placesViewController      = [[FDPlacesViewController alloc] initWithDelegate:self];
    self.recommendedTableViewController = [[FDRecommendedTableViewController alloc] initWithDelegate:self];
    self.keepersViewController          = [[FDRecommendedTableViewController alloc]  initWithDelegate:self];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blackLogo.png"]];
    
    self.addPostButton.layer.shadowOffset = CGSizeMake(0,0);
    self.addPostButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.addPostButton.layer.shadowRadius = 3.0;
    self.addPostButton.layer.shadowOpacity = .4;
    
    //hide slider without animations
    [self.feedContainerView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
    _scrollView.transform = CGAffineTransformMakeTranslation(0, -134);
    self.clipViewBackground.transform = CGAffineTransformMakeTranslation(0, -134);
    clipView.transform = CGAffineTransformMakeTranslation(0, -134);

    self.clipViewBackground.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.clipViewBackground.layer.shouldRasterize = YES;

    /*int screenWidth = self.view.bounds.size.width;
    int screenHeight = self.view.bounds.size.height;
    BOOL existingUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"existingUser"];
    if (!existingUser) {
        [self.navigationController setNavigationBarHidden:YES];
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
        [blackView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.70]];
        UIImageView *newUser = [[UIImageView alloc] init];
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen ].bounds.size.height == 568.0)){
            [newUser setImage:[UIImage imageNamed:@"newUser@2x.png"]];
        } else {
            [newUser setImage:[UIImage imageNamed:@"newUserShort.png"]];
        }
        [newUser setFrame:CGRectMake(0,0,320,screenHeight)];
        [blackView addSubview:newUser];
        [blackView setTag:333];
        UIButton *dismiss = [[UIButton alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
        [dismiss setBackgroundColor:[UIColor clearColor]];
        [dismiss addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
        [blackView addSubview:dismiss];
        [self.view addSubview:blackView];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"existingUser"];
    }*/
    
    /*self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,-44,320,44)];
    self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplay.delegate = self;
    
    //customize the searchbar
    self.searchBar.placeholder = @"Search food, drink, or descriptors";
    for (UIView *view in self.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader"]];
            [view addSubview:header];
            break;
        }
    }
    for(UIView *subView in self.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kAvenirMedium size:14];
        }
    }
    
    [self.view insertSubview:self.searchBar belowSubview:_scrollView];
    [self.searchBar setHidden:YES];*/
    
    self.slidingViewController.panGesture.enabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideSlider)
                                                 name:@"HideSlider"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(revealSlider)
                                                 name:@"RevealSlider"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postToInstagram)
                                                 name:@"PostToInstagram"
                                               object:nil];

    
    UIImage *emptyBarButton = [UIImage imageNamed:@"emptyBarButton.png"];
    //[self.searchButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.menuButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    _scrollView.clipsToBounds = NO;
	_scrollView.pagingEnabled = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [_scrollView setContentSize:CGSizeMake(352,78)];
    //if ([[NSUserDefaults standardUserDefaults] boolForKey:@"JustLaunched"]){
        // show the featured feed initially
        //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"JustLaunched"];
        [self showFeatured];
        //[self hideLabelsExcept:self.featuredLabel];
    //} else {
        //[self showFeed];
        //[self hideLabelsExcept:self.feedLabel];
        //[_scrollView setContentOffset:CGPointMake(88,0)];
    //}
    //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kJustPosted];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.featuredLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.recLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.feedLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.keepersLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int currentPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (self.page < currentPage) self.movedRight = YES;
    else self.movedRight = NO;
    switch (currentPage) {
        case 0:
            [self showFeatured];
            [self.addPostButton setFrame:CGRectMake(130,self.view.frame.size.height-55,55,55)];
            [self hideLabelsExcept:self.featuredLabel];
            break;
        case 1:
            [self showFeed];
            [self.addPostButton setFrame:CGRectMake(130,self.view.frame.size.height-55,55,55)];
            [self hideLabelsExcept:self.feedLabel];
            break;
        /*case 2:
            [self showNearby];
            [self.addPostButton setFrame:CGRectMake(130,self.view.frame.size.height,55,55)];
            [self hideLabelsExcept:self.nearbyLabel];
            break;*/
        case 2:
            [self showRecommended];
            [self.addPostButton setFrame:CGRectMake(130,self.view.frame.size.height,55,55)];
            [self hideLabelsExcept:self.recLabel];
            break;
        case 3:
            [self showKeepers];
            [self.addPostButton setFrame:CGRectMake(130,self.view.frame.size.height,55,55)];
            [self hideLabelsExcept:self.keepersLabel];
            break;
        default:
            break;
    }
    self.page = currentPage;
}

- (void)hideLabelsExcept:(UILabel *)feed{
    for (UIView *view in _scrollView.subviews) {
        if ([view isMemberOfClass:[UILabel class]]){
            UILabel *label = (UILabel *)view;
            if (label.text != feed.text) {
                [UIView animateWithDuration:.25f animations:^{
                    label.alpha = 0.0;
                    feed.alpha = 1.0;
                }];
            }
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastContentOffsetX = scrollView.contentOffset.x;
    _lastContentOffsetY = scrollView.contentOffset.y;
}

- (IBAction)rightBarButtonAction {
    if (self.feedContainerView.frame.origin.y == 0){
        [self revealSlider];
    } else {
        [self hideSlider];
    }
}

- (void)revealSlider {
    
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionTransitionCurlDown animations:^{
        [self.feedContainerView setFrame:CGRectMake(0,78,320,self.view.bounds.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(1.4*M_PI/180);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, 8);
        
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);

        clipView.transform = CGAffineTransformConcat(rotate, translation);
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.feedContainerView.transform = CGAffineTransformIdentity;
            _scrollView.transform = CGAffineTransformMakeRotation(-0.8*M_PI/180);
            self.clipViewBackground.transform = CGAffineTransformMakeRotation(-0.8*M_PI/180);
            clipView.transform = CGAffineTransformMakeRotation(-0.8*M_PI/180);
            [self showAllLabels];
        }  completion:^(BOOL finished) {
            [UIView animateWithDuration:.125 animations:^{
                _scrollView.transform = CGAffineTransformIdentity;
                self.clipViewBackground.transform = CGAffineTransformIdentity;
                clipView.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
}

- (void)hideSlider {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.feedContainerView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(0);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, -85);
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        clipView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);
            } completion:^(BOOL finished) {
                [self hideLabels];
            }];
}

- (void) hideLabels{
    switch (self.page) {
        case 0:
            [self hideLabelsExcept:self.featuredLabel];
            break;
        case 1:
            [self hideLabelsExcept:self.feedLabel];
            break;
        /*case 2:
            [self hideLabelsExcept:self.nearbyLabel];
            break;*/
        case 2:
            [self hideLabelsExcept:self.recLabel];
            break;
        case 3:
            [self hideLabelsExcept:self.keepersLabel];
            break;
        default:
            break;
    }
}
- (void) showAllLabels {
    [UIView animateWithDuration:.4f delay:.1f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.feedLabel.alpha = 1.0;
        self.featuredLabel.alpha = 1.0;
        self.keepersLabel.alpha = 1.0;
        self.recLabel.alpha = 1.0;
    }completion:^(BOOL finished) {
        
    }];
    
}
/*- (void)dismissSelf {
    UIView *blackView = [self.view viewWithTag:333];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.25f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        [blackView setAlpha:0.0f];
    }
                     completion: ^(BOOL finished){
                         [blackView removeFromSuperview];
    }];
}*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.slidingViewController.panGesture.enabled = NO;
}

- (void)viewDidUnload
{
    [self setFeedContainerView:nil];
    //[self setSearchButtonItem:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowPost"]) {
        FDPostViewController *vc = segue.destinationViewController;
        [vc setPostIdentifier:[(FDPost *)sender identifier]];
    } else if ([segue.identifier isEqualToString:@"AddPost"]) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [FDPost resetUserPost];
    } else if ([segue.identifier isEqualToString:@"ShowMap"]) {
        FDPlaceViewController *vcForMap = segue.destinationViewController;
        [vcForMap setPostIdentifier:[(FDPost *)sender identifier]];
    } else if ([segue.identifier isEqualToString:@"ShowProfileFromLikers"]){
        UIButton *button = (UIButton *)sender;
        FDProfileViewController *vc = segue.destinationViewController;
        [vc initWithUserId:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"ShowPlace"]){
        FDPlaceViewController *placeView = [segue destinationViewController];
        FDPost *post = (FDPost *) sender;
        [placeView setVenueId:post.foursquareid];
    }
}

#pragma mark - Private Methods

- (void)showFeed {
    //[self.searchButtonItem setImage:[UIImage imageNamed:@"emptyBarButton"]];
    //[self.searchButtonItem setEnabled:NO];
    //self.title = @"FRIENDS";
    [self showPostViewController:self.feedTableViewController];
}

- (void)showFeatured {
    //[self.searchButtonItem setImage:[UIImage imageNamed:@"emptyBarButton"]];
    //[self.searchButtonItem setEnabled:NO];
    //self.title = @"FEATURED";
    [self showPostViewController:self.featuredGridViewController];
}

- (void)showRecommended {
    //[self.searchButtonItem setImage:[UIImage imageNamed:@"emptyBarButton"]];
    //[self.searchButtonItem setEnabled:NO];
    //self.title = @"RECOMMENDED";
    [self.recommendedTableViewController setShouldShowKeepers:NO];
    [self showPostViewController:self.recommendedTableViewController];
}

- (void)showNearby {
    //self.title = @"NEARBY";
    //[self.searchButtonItem setImage:[UIImage imageNamed:@"magnifier"]];
    //[self.searchButtonItem setEnabled:YES];
    [self showPostViewController:self.placesViewController];
}

- (void)showKeepers {
    //[self.searchButtonItem setImage:[UIImage imageNamed:@"magnifier"]];
    //[self.searchButtonItem setEnabled:YES];
    [self.keepersViewController setShouldShowKeepers:YES];
    [self showPostViewController:self.keepersViewController];
}

- (void)showPostViewController:(UIViewController *)toViewController {
    if (toViewController == self.currentChildViewController) return;
    else if (self.currentChildViewController == nil) {
        
        [toViewController willMoveToParentViewController:self];
        [self addChildViewController:toViewController];
        toViewController.view.frame = self.feedContainerView.bounds;
        [self.feedContainerView addSubview:toViewController.view];
        self.currentChildViewController = toViewController;
    } else {
        // inform the current controller that it's being orphaned (Oh no!)
        [self.currentChildViewController willMoveToParentViewController:nil];
    
        //add the new view controller as a child
        [self addChildViewController:toViewController];

        // perform the view switch
        //toViewController.view.alpha = 0.0f;
        toViewController.view.frame = self.feedContainerView.bounds;
        
        if (self.movedRight) {
            toViewController.view.transform = CGAffineTransformMakeTranslation(self.feedContainerView.bounds.size.width, 0);
        } else {
            toViewController.view.transform = CGAffineTransformMakeTranslation(-self.feedContainerView.bounds.size.width, 0);
        }
            
        [self transitionFromViewController:self.currentChildViewController
                          toViewController:toViewController
                                  duration:0.15f
                                   options:0
                                animations:^{
                                    CGAffineTransform hiddenTransform;
                                    if (self.movedRight) {
                                        hiddenTransform = CGAffineTransformMakeTranslation(-self.feedContainerView.bounds.size.width, 0);
                                    } else {
                                        hiddenTransform = CGAffineTransformMakeTranslation(self.feedContainerView.bounds.size.width, 0);
                                    }
                                    hiddenTransform = CGAffineTransformScale(hiddenTransform, 0.3, 0.3);
                                    self.currentChildViewController.view.transform = hiddenTransform;
                                    toViewController.view.transform = CGAffineTransformIdentity;
                                }
                                completion:^(BOOL finished) {
                                    //[self.currentChildViewController removeFromParentViewController];
                                    self.currentChildViewController.view.transform = CGAffineTransformIdentity;
                                    [toViewController didMoveToParentViewController:self];
                                    self.currentChildViewController = toViewController;
                                }
         ];
    }
}
                                                                 
- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    int badgeCount = 0;
    // Resets the badge count when the view is opened
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController refresh];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController grow];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (IBAction)activateSearch:(UIBarButtonItem *)sender {
    if (!self.navigationController.navigationBar.isHidden){
        [self hideSlider];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            //[self.searchBar setFrame:CGRectMake(0,0,320,44)];
            [self.feedContainerView setFrame:CGRectMake(0,44,320,self.view.frame.size.height)];
        }];
        //[self.searchBar setHidden:NO];
    } else {
        [UIView animateWithDuration:.3f animations:^{
            //[self.searchBar setFrame:CGRectMake(0,-44,320,44)];
            [self.feedContainerView setFrame:CGRectMake(0,26,320,self.view.frame.size.height)];
            //[self.searchBar setHidden:YES];
        }];
    }
}

- (NSString *)searchText {
    return self.searchBar.text;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView setHidden:YES];
    NSLog(@"controller searchBar text: %@",controller.searchBar.text);

}

- (void)postToInstagram {
    UIImage *instaImage = FDPost.userPost.photoImage;
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        //now create a file path with an .igo file extension
        NSString *instaPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/instaImage.igo"];
        [UIImageJPEGRepresentation(instaImage,1.0)writeToFile:instaPath atomically:YES];
        
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:instaPath]];
        
        self.documentInteractionController.UTI = @"com.instagram.exclusivegram";
        self.documentInteractionController.annotation = [NSDictionary dictionaryWithObject:@"#FOODIA" forKey:@"InstagramCaption"];
        
        [((FDAppDelegate *)[UIApplication sharedApplication].delegate) hideLoadingOverlay];
        [self performSelector:@selector(showIg) withObject:nil afterDelay:2.0];
    }
}

-(void)showIg {
    [self.documentInteractionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:true];
}

#pragma mark - FDPostTableViewControllerDelegate Methods

- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPost:(FDPost *)post {
    [self.navigationController setNavigationBarHidden:NO];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPlace:(FDVenue *)place {
    [self.navigationController setNavigationBarHidden:NO];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    NSLog(@"place we're going to: %@",place.name);
    [self performSegueWithIdentifier:@"ShowPlace" sender:place];
}

#pragma mark - FDPostGridViewControllerDelegate Methods

- (void)postGridViewController:(FDPostGridViewController *)controller didSelectPost:(FDPost *)post {
    NSLog(@"did select a post: %@",post.identifier);
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

@end
