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
#import "FDUser.h"
#import "FDPostViewController.h"
#import "ECSlidingViewController.h"
#import "FDPlaceViewController.h"
#import "FDMenuViewController.h"
#import "FDProfileViewController.h"
#import "TWAPIManager.h"
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWSignedRequest.h"
#import "FDAppDelegate.h"
#import <Accounts/Accounts.h>
#import "FDPostCell.h"
#import "Utilities.h"
#import "UIButton+WebCache.h"
#import <MessageUI/MessageUI.h>
#import "FDCustomSheet.h"
#import "FDRecommendViewController.h"
#define kSearchBarPlaceholder @"Find food, drinks or places"
#define kInitialSliderHideConstant 150

@interface FDFeedViewController () <FDPostTableViewControllerDelegate, FDPostGridViewControllerDelegate, UIScrollViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, CLLocationManagerDelegate, UIAlertViewDelegate> {
    BOOL isSearching;
    BOOL shouldBeginEditing;
    BOOL showingDistance;
    BOOL sliderRevealed;
    UIImage *originalShadowImage;
    CLLocation *currentLocation;
}

@property (nonatomic,strong) FDFeedTableViewController          *feedTableViewController;
@property (nonatomic,strong) FDFeaturedGridViewController      *featuredGridViewController;
@property (nonatomic,strong) FDRecommendedTableViewController   *recommendedTableViewController;
@property (nonatomic,strong) FDRecommendedTableViewController    *keepersViewController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sliderButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButtonItem;
@property (retain, nonatomic) IBOutlet UIButton *addPostButton;
@property (weak, nonatomic) IBOutlet UILabel *feedLabel;
@property (weak, nonatomic) IBOutlet UILabel *featuredLabel;
//@property (weak, nonatomic) IBOutlet UILabel *myPostsLabel;
@property (weak, nonatomic) IBOutlet UILabel *keepersLabel;
@property (weak, nonatomic) IBOutlet UILabel *nearbyLabel;
@property (weak, nonatomic) IBOutlet UILabel *recLabel;
@property (strong, nonatomic) UIButton *logoImageButton;
@property (nonatomic, weak) UIViewController *currentChildViewController;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property BOOL movedRight;
@property int page;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (strong, nonatomic) UIActionSheet *twitterActionSheet;
@property (strong, nonatomic) SLComposeViewController *tweetSheet;
@property (weak, nonatomic) IBOutlet UITableView *resultsTableView;
@property (strong, nonatomic) NSMutableArray *searchPosts;
@property (strong, nonatomic) NSString *noPostSearchString;
@property (strong, nonatomic) UIView *editContainerView;
@property (strong, nonatomic) UIButton *sortByDistanceButton;
@property (strong, nonatomic) UIButton *sortByPopularityButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
- (IBAction)revealMenu:(UIBarButtonItem *)sender;
@end

@implementation FDFeedViewController
@synthesize lastContentOffsetX = _lastContentOffsetX;
@synthesize lastContentOffsetY = _lastContentOffsetY;
@synthesize page = _page;
@synthesize documentInteractionController = _documentInteractionController;
@synthesize twitterActionSheet = _twitterActionSheet;
@synthesize tweetSheet = _tweetSheet;
@synthesize goToComment;
@synthesize swipedCells;
@synthesize noPostSearchString = _noPostSearchString;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Looking at Feed View" timed:YES];
    //self.trackedViewName = @"Initial Feed View";
    self.sliderButtonItem.tintColor = [UIColor blackColor];
    _accountStore = [[ACAccountStore alloc] init];
    _apiManager = [[TWAPIManager alloc] init];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        originalShadowImage = self.navigationController.navigationBar.shadowImage;
    }
    [self.navigationItem.rightBarButtonItem setBackgroundImage:[UIImage imageNamed:@"emptyBarButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController shrink];
    
    self.feedTableViewController        = [[FDFeedTableViewController alloc]        initWithDelegate:self];
    self.featuredGridViewController    = [[FDFeaturedGridViewController alloc]    initWithDelegate:self];
    //self.placesViewController      = [[FDPlacesViewController alloc] initWithDelegate:self];
    self.recommendedTableViewController = [[FDRecommendedTableViewController alloc] initWithDelegate:self];
    self.keepersViewController          = [[FDRecommendedTableViewController alloc]  initWithDelegate:self];
    self.page = 0;
    self.addPostButton.layer.shadowOffset = CGSizeMake(0,0);
    self.addPostButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.addPostButton.layer.shadowRadius = 5.0;
    self.addPostButton.layer.shadowOpacity = .5;
    
    //location manager stuff
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    //hide slider without animations
    [self.feedContainerView setFrame:CGRectMake(0,0,320,self.feedContainerView.frame.size.height)];
    _scrollView.transform = CGAffineTransformMakeTranslation(0, -kInitialSliderHideConstant);
    self.clipViewBackground.transform = CGAffineTransformMakeTranslation(0, -kInitialSliderHideConstant);
    clipView.transform = CGAffineTransformMakeTranslation(0, -kInitialSliderHideConstant);
    self.clipViewBackground.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.clipViewBackground.layer.shouldRasterize = YES;
    [self.clipViewBackground setAlpha:0.0];
    [clipView setAlpha:0.0];
    [_scrollView setAlpha:0.0];
    
    self.logoImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.logoImageButton setImage:[UIImage imageNamed:@"upsideDownIcon"] forState:UIControlStateNormal];
    [self.logoImageButton addTarget:self action:@selector(revealSlider) forControlEvents:UIControlEventTouchUpInside];
    [self.logoImageButton setFrame:CGRectMake(87,-1,41,64)];
    //[self.logoImageView setFrame:CGRectMake(61,31,94,25)];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchPosts = [NSMutableArray array];
    self.resultsTableView.delegate = self;
    self.resultsTableView.dataSource = self;
    //customize the searchbar
    self.searchBar.placeholder = kSearchBarPlaceholder;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

    for (UIView *view in self.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"thinSearchBackground"]];
            [view addSubview:header];
            break;
        }
    }
    for(UIView *subView in self.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            //searchField.layer.cornerRadius = 5.0f;
            [searchField.layer setBackgroundColor:[UIColor clearColor].CGColor];
            searchField.layer.shadowColor = [UIColor blackColor].CGColor;
            searchField.layer.shadowOpacity = .5f;
            searchField.layer.shadowRadius = 2.25f;
            searchField.layer.shadowOffset = CGSizeMake(0,0);
            searchField.clipsToBounds = NO;
            [searchField setFont:[UIFont fontWithName:kHelveticaNeueThin size:13]];
        }
    }
    
    self.slidingViewController.panGesture.enabled = YES;
    
    //set up swiped cells thing
    self.swipedCells = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellClosed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideSlider)
                                                 name:@"HideSlider"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(revealSlider)
                                                 name:@"RevealSlider"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideKeyboard)
                                                 name:@"HideKeyboard"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postToInstagram)
                                                 name:@"PostToInstagram"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postToTwitter:)
                                                 name:@"PostToTwitter"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postToFacebook:)
                                                 name:@"PostToFacebook"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refresh)
                                                 name:@"RefreshFeed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostTimedOut) name:@"NewPostTimedOut" object:nil];
    
    UIImage *emptyBarButton = [UIImage imageNamed:@"emptyBarButton.png"];
    //[self.searchButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.menuButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    _scrollView.clipsToBounds = NO;
	_scrollView.pagingEnabled = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [_scrollView setContentSize:CGSizeMake(352,78)];    
    
    UIView *navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 88)];
    [self.searchBar setTintColor:[UIColor whiteColor]];
    [self.searchBar setFrame:CGRectMake(0, -44, 220, 44)];
    [self.searchBar setAlpha:0.0];
    [navigationView addSubview:self.logoImageButton];
    [navigationView addSubview:self.searchBar];

    self.navigationItem.titleView = navigationView;
    
    //optionally show featured or feed sections first. this boolean is controlled through the settings view
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldShowFeaturedFirst]){
        [self showFeatured];
    } else {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kShouldShowFeaturedFirst]){
            [self showFeed];
            [_scrollView setContentOffset:CGPointMake(88,0)];
        } else {
            [self showFeatured];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        if (sliderRevealed) {
            self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
        } else {
            self.navigationController.navigationBar.shadowImage = originalShadowImage;
        }
    }
}

- (void)newPostTimedOut {
    [[[UIAlertView alloc] initWithTitle:@"Uh-oh" message:@"Sorry, but we weren't able to send your post. If you gave us permission to access your photo album, we saved your post photo there." delegate:self cancelButtonTitle:@"Okey Dokey" otherButtonTitles:nil] show];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error: %@",error.description);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([[locations lastObject] horizontalAccuracy] < 0) return;
    if (!currentLocation) currentLocation = [[CLLocation alloc] init];
    currentLocation = [locations lastObject];
    [self.locationManager stopUpdatingLocation];
}

- (void)refresh {
    [self.resultsTableView reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int currentPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (currentPage != self.page && scrollView.contentOffset.x) [self hideKeyboard];
    if (self.page < currentPage) self.movedRight = YES;
    else self.movedRight = NO;
    switch (currentPage) {
        case 0:
            [self showFeatured];
            [self.addPostButton setFrame:CGRectMake(self.addPostButton.frame.origin.x,self.view.frame.size.height-55,55,55)];
            [self hideLabelsExcept:self.featuredLabel];
            break;
        case 1:
            [self showFeed];
            [self.addPostButton setFrame:CGRectMake(self.addPostButton.frame.origin.x,self.view.frame.size.height-55,55,55)];
            [self hideLabelsExcept:self.feedLabel];
            break;
        case 2:
            [self showRecommended];
            [self.addPostButton setFrame:CGRectMake(self.addPostButton.frame.origin.x,self.view.frame.size.height,55,55)];
            [self hideLabelsExcept:self.recLabel];
            break;
        case 3:
            [self showKeepers];
            [self.addPostButton setFrame:CGRectMake(self.addPostButton.frame.origin.x,self.view.frame.size.height,55,55)];
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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    }
    [UIView animateWithDuration:.19 animations:^{
        [self.logoImageButton setAlpha:0.0];
    }];
    [self hideKeyboard];
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionTransitionCurlDown animations:^{
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"up_arrow"]];
        [self.feedContainerView setFrame:CGRectMake(0,78,320,self.feedContainerView.frame.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(1.4*M_PI/180);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, 8);
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);
        clipView.transform = CGAffineTransformConcat(rotate, translation);
        self.searchBar.transform = CGAffineTransformMakeTranslation(0, 66);
        [self.searchBar setAlpha:1.0];
        self.logoImageButton.transform = CGAffineTransformMakeTranslation(0, 44);
        [self.clipViewBackground setAlpha:1.0];
        [clipView setAlpha:1.0];
        [_scrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        sliderRevealed = YES;
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
    if (!isSearching) {
        [self hideKeyboard];
        [self hideSearchBar];
    }
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
            self.navigationController.navigationBar.shadowImage = originalShadowImage;
        }
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"down_arrow"]];
        [self.feedContainerView setFrame:CGRectMake(0,0,320,self.feedContainerView.frame.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(0);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, -kInitialSliderHideConstant);
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        clipView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);
        self.logoImageButton.transform = CGAffineTransformIdentity;
        [self.logoImageButton setAlpha:1.0];
        [self.clipViewBackground setAlpha:0.0];
        [clipView setAlpha:0.0];
        [_scrollView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self hideLabels];
        showingDistance = NO;
        sliderRevealed = NO;
    }];
}

- (void)hideSearchBar {
    [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.searchBar.transform = CGAffineTransformIdentity;
        [self.searchBar setAlpha:1.0];
    } completion:^(BOOL finished) {
        
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

- (void)viewWillDisappear:(BOOL)animated {
    self.slidingViewController.panGesture.enabled = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        self.navigationController.navigationBar.shadowImage = originalShadowImage;
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setFeedContainerView:nil];
    [self setSwipedCells:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowPost"]) {
        FDPostViewController *vc = segue.destinationViewController;
        if (self.goToComment) {[vc setShouldShowComment:YES];NSLog(@"should be going to comment");}
        else [vc setShouldShowComment:NO];
        [vc setPostIdentifier:[(FDPost *)sender identifier]];
    } else if ([segue.identifier isEqualToString:@"AddPost"]) {
        [FDPost resetUserPost];
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
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
    //self.title = @"FRIENDS";
    [self showPostViewController:self.feedTableViewController];
}

- (void)showFeatured {
    //self.title = @"FEATURED";
    [self showPostViewController:self.featuredGridViewController];
}

- (void)showRecommended {
    //self.title = @"RECOMMENDED";
    [self.recommendedTableViewController setShouldShowKeepers:NO];
    [self.recommendedTableViewController performSelector:@selector(refresh) withObject:nil afterDelay:.5];
    [self showPostViewController:self.recommendedTableViewController];
}

- (void)showKeepers {
    [self.keepersViewController setShouldShowKeepers:YES];
    [self.keepersViewController performSelector:@selector(refresh) withObject:nil afterDelay:.5];
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
        [self.currentChildViewController willMoveToParentViewController:nil];
        [self addChildViewController:toViewController];
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
    [self hideKeyboard];
    [self.slidingViewController anchorTopViewTo:ECRight];
    int badgeCount = 0;
    // Resets the badge count when the view is opened
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController refresh];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController grow];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchPosts.count) return self.searchPosts.count;
    else if (_noPostSearchString.length) return 1;
    else return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 155;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchPosts.count > 0){
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        }
        FDPost *post = [self.searchPosts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        if (showingDistance){
            CLLocationDistance distance = [currentLocation distanceFromLocation:post.location];
            [cell.timeLabel setText:[NSString stringWithFormat:@"%@",[self stringWithDistance:distance]]];
        }
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = post.user.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        cell.detailPhotoButton.tag = indexPath.row;
        [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        cell = [self showLikers:cell forPost:post];
        [cell bringSubviewToFront:cell.likersScrollView];
        
        //capture touch event to show user place map
        if (post.locationName.length){
            [cell.locationButton setHidden:NO];
            [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
            cell.locationButton.tag = indexPath.row;
        }
        
        [cell.recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        cell.recButton.tag = indexPath.row;
        
        cell.commentButton.tag = indexPath.row;
        [cell.commentButton addTarget:self action:@selector(comment:) forControlEvents:UIControlEventTouchUpInside];
        
        //swipe cell accordingly
        if ([self.swipedCells indexOfObject:post.identifier] != NSNotFound){
            [cell.scrollView setContentOffset:CGPointMake(271,0)];
        } else [cell.scrollView setContentOffset:CGPointZero];
        
        if (cell.scrollView.contentOffset.x > 270) {
            [cell.slideCellButton setHidden:NO];
        } else {
            [cell.slideCellButton setHidden:YES];
        }
        return cell;
    } else {
        [self.resultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        static NSString *NoPostsCellIdentifier = @"NoPostsCellIdenfitier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoPostsCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoPostsCellIdentifier];
        }
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
        [cell.textLabel setText:self.noPostSearchString];
        [cell.textLabel setNumberOfLines:0];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostCell class]]){
        FDPostCell *thisCell = (FDPostCell*)cell;
        [UIView animateWithDuration:.25 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
            [thisCell.photoImageView setAlpha:0.0];
            [thisCell.posterButton setAlpha:0.0];
        }];
    }
}

- (void)comment:(id)sender{
    self.goToComment = YES;
    UIButton *button = (UIButton*)sender;
    FDPost *post = (FDPost*)[self.searchPosts objectAtIndex:button.tag];
    NSDictionary *userInfo = @{@"identifier":[NSString stringWithFormat:@"%@",post.identifier]};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RowToReloadFromMenu" object:nil userInfo:userInfo];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

- (void)didSelectRow:(id)sender {
    UIButton *button = (UIButton*)sender;
    self.goToComment = NO;
    FDPost *post = (FDPost*)[self.searchPosts objectAtIndex:button.tag];
    NSDictionary *userInfo = @{@"identifier":[NSString stringWithFormat:@"%@",post.identifier]};
     [[NSNotificationCenter defaultCenter] postNotificationName:@"RowToReloadFromMenu" object:nil userInfo:userInfo];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

-(void)showPlace: (id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    [self performSegueWithIdentifier:@"ShowPlace" sender:[self.searchPosts objectAtIndex:button.tag]];
}

#pragma mark - Display likers

- (FDPostCell *)showLikers:(FDPostCell *)cell forPost:(FDPost *)post{
    NSDictionary *likers = post.likers;
    NSDictionary *viewers = post.viewers;
    [cell.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.likersScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *viewer in viewers) {
        if ([viewer objectForKey:@"id"] != [NSNull null]){
            UIImageView *face = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light_smile"]];
            UIButton *viewerButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [viewerButton setFrame:CGRectMake(((space+imageSize)*index),0,imageSize, imageSize)];
            [cell.likersScrollView addSubview:viewerButton];
            //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
            viewerButton.titleLabel.text = [[viewer objectForKey:@"id"] stringValue];
            viewerButton.titleLabel.hidden = YES;
            [viewerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
            if ([viewer objectForKey:@"facebook_id"] != [NSNull null] && [[viewer objectForKey:@"facebook_id"] length] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [viewerButton setImageWithURL:[Utilities profileImageURLForFacebookID:[viewer objectForKey:@"facebook_id"]] forState:UIControlStateNormal];
            } else if ([viewer objectForKey:@"avatar_url"] != [NSNull null]) {
                [viewerButton setImageWithURL:[viewer objectForKey:@"avatar_url"] forState:UIControlStateNormal];
            }
            
            viewerButton.imageView.layer.cornerRadius = 17.0;
            //rasterize to improve performance
            [viewerButton.imageView setBackgroundColor:[UIColor clearColor]];
            [viewerButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
            viewerButton.imageView.layer.shouldRasterize = YES;
            viewerButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            
            face.frame = CGRectMake((((space+imageSize)*index)+18),18,20,20);
            
            for (NSDictionary *liker in likers) {
                if ([[liker objectForKey:@"id"] isEqualToNumber:[viewer objectForKey:@"id"]]){
                    [cell.likersScrollView addSubview:face];
                    break;
                }
            }
            index++;
        }
        [cell.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    }
    return cell;
}

-(void)showProfile:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIStoryboard *storyboard;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                               bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                               bundle:nil];
    }
    FDProfileViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    [vc initWithUserId:button.titleLabel.text];
    [self.navigationController pushViewController:vc animated:YES];
    
}

-(void)profileTappedFromLikers:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    isSearching = YES;
    [self hideSlider];
    [UIView animateWithDuration:.25 animations:^{
        [self.resultsTableView setAlpha:.85];
    }];
}

- (void)setUpRankControls {
    //set up editcontainer stuff
    if (self.editContainerView == nil){
        self.editContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,-44,320,44)];
        [self.editContainerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"newFoodiaHeader"]]];
        
        self.sortByDistanceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.sortByPopularityButton setBackgroundImage:[UIImage imageNamed:@"commentBubble"] forState:UIControlStateNormal];
        [self.sortByDistanceButton setFrame:CGRectMake(170, 2, 140, 44)];
        [self.sortByDistanceButton setTitle:@"Distance" forState:UIControlStateNormal];
        [self.sortByDistanceButton.titleLabel setTextColor:[UIColor darkGrayColor]];
        self.sortByDistanceButton.layer.cornerRadius = 17.0;
        self.sortByDistanceButton.clipsToBounds = YES;
        [self.sortByDistanceButton addTarget:self action:@selector(sortSearchByDistance) forControlEvents:UIControlEventTouchUpInside];
        
        
        self.sortByPopularityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.sortByPopularityButton setBackgroundImage:[UIImage imageNamed:@"commentBubble"] forState:UIControlStateNormal];
        [self.sortByPopularityButton setTitle:@"Popularity" forState:UIControlStateNormal];
        [self.sortByPopularityButton setFrame:CGRectMake(10, 2, 140, 44)];

        self.sortByPopularityButton.layer.cornerRadius = 17.0;
        self.sortByPopularityButton.clipsToBounds = YES;
        [self.sortByPopularityButton addTarget:self action:@selector(sortSearchByPopularity) forControlEvents:UIControlEventTouchUpInside];
    
        [self.sortByPopularityButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
        [self.sortByDistanceButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
        [self resetButtonColors];
        [self.editContainerView addSubview:self.sortByDistanceButton];
        [self.editContainerView addSubview:self.sortByPopularityButton];
        
        self.resultsTableView.tableHeaderView = self.editContainerView;
    }
}

- (void)resetButtonColors {
    [UIView animateWithDuration:.2 animations:^{
        [self.sortByPopularityButton setBackgroundImage:[UIImage imageNamed:@"commentBubble"] forState:UIControlStateNormal];
        [self.sortByDistanceButton setBackgroundImage:[UIImage imageNamed:@"commentBubble"] forState:UIControlStateNormal];
        [self.sortByPopularityButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self.sortByDistanceButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    isSearching = NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    showingDistance = NO;
    [[FDAPIClient sharedClient] getPostsForQuery:searchBar.text Success:^(id result) {
        self.searchPosts = result;
        self.noPostSearchString = [NSString stringWithFormat:@"Sorry, but we couldn't find any posts with %@ in them",self.searchBar.text];
        [self.resultsTableView reloadData];
        [UIView animateWithDuration:.25 animations:^{
            [self.resultsTableView setAlpha:1.0];
        }];
        self.resultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [self setUpRankControls];
    } failure:^(NSError *error) {
        NSLog(@"error from search method: %@",error.description);
    }];
    [searchBar endEditing:YES];
}

- (void)sortSearchByDistance {
    showingDistance = YES;
    [self.searchPosts removeAllObjects];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [[FDAPIClient sharedClient] getDistancePostsForQuery:self.searchBar.text withLocation:currentLocation  Success:^(id result) {
        self.searchPosts = result;
        self.noPostSearchString = [NSString stringWithFormat:@"Sorry, but we couldn't find any posts with %@ in them",self.searchBar.text];
        [self.resultsTableView reloadData];
        [UIView animateWithDuration:.25 animations:^{
            [self.resultsTableView setAlpha:1.0];
        }];
        self.resultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } failure:^(NSError *error) {
        NSLog(@"error from search method: %@",error.description);
    }];
    [self.searchBar endEditing:YES];
    [self resetButtonColors];
    [self.sortByDistanceButton setBackgroundImage:[UIImage imageNamed:@"commentBubbleSelected"] forState:UIControlStateNormal];
    [self.sortByDistanceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)sortSearchByPopularity {
    showingDistance = NO;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self.searchPosts removeAllObjects];
    [[FDAPIClient sharedClient] getPopularPostsForQuery:self.searchBar.text Success:^(id result) {
        self.searchPosts = result;
        self.noPostSearchString = [NSString stringWithFormat:@"Sorry, but we couldn't find any posts with %@ in them",self.searchBar.text];
        [self.resultsTableView reloadData];
        [UIView animateWithDuration:.25 animations:^{
            [self.resultsTableView setAlpha:1.0];
        }];
        self.resultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } failure:^(NSError *error) {
        NSLog(@"error from search method: %@",error.description);
    }];
    [self.searchBar endEditing:YES];
    [self resetButtonColors];
    [self.sortByPopularityButton setBackgroundImage:[UIImage imageNamed:@"commentBubbleSelected"] forState:UIControlStateNormal];
    [self.sortByPopularityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)hideKeyboard {
    [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.resultsTableView setAlpha:0.0];
        [self.searchBar setText:@""];
    } completion:^(BOOL finished) {
        [self.searchPosts removeAllObjects];
        [self.resultsTableView reloadData];
        [self.resultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        self.noPostSearchString = @"";
        [self.searchBar endEditing:YES];
        [self.searchBar resignFirstResponder];
        
    }];
}

//take care of swiped cells
- (void)swipedCells:(NSNotification*)notification {
    NSString *identifier = [notification.userInfo objectForKey:@"identifier"];
    if ([self.swipedCells indexOfObject:identifier] == NSNotFound){
        [self.swipedCells addObject:identifier];
    } else {
        [self.swipedCells removeObject:identifier];
    }
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
        [self showIg];
    } else {
        UIAlertView *errorToShare = [[UIAlertView alloc] initWithTitle:@"Instagram unavailable " message:@"We were unable to connect to Instagram on this device" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [errorToShare show];
    }
}

-(void)showIg {
    NSLog(@"showIg method");
    [self.documentInteractionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
}

- (void)postToTwitter:(NSNotification*)notification {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0){
        __weak SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        NSString *postId = [notification.userInfo objectForKey:@"identifier"];
        [tweetSheet setInitialText:[NSString stringWithFormat:@"%@ on #FOODIA | http://posts.foodia.com/p/%@", FDPost.userPost.foodiaObject, postId]];
        if (FDPost.userPost.photoImage){
            [tweetSheet addImage:FDPost.userPost.photoImage];
        }
        tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result) {
            [tweetSheet dismissViewControllerAnimated:YES completion:^{
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]) {
                    NSLog(@"should be posting to instagram");
                    [self performSelector:@selector(postToInstagram) withObject:nil afterDelay:0.5];
                }
            }];
            /*switch (result) {
                 case TWTweetComposeViewControllerResultCancelled:
                    break;
                 case TWTweetComposeViewControllerResultDone:
                 default:
                    break;
            }*/
            
        };
        [self presentViewController:tweetSheet animated:YES completion:nil];
    
    //if (![[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsFacebookActive] && ![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]) [self performSelector:@selector(showTwitter) withObject:nil afterDelay:0.1];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Twitter unavailable" message:@"Sorry, but we weren't able to connect to your Twitter account on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

-(void)showTwitter {
    [self presentViewController:self.tweetSheet animated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"should be showing twitter action sheet");
    if (actionSheet == self.twitterActionSheet){
        if (buttonIndex != (actionSheet.numberOfButtons - 1)) {
            [_apiManager
             performReverseAuthForAccount:_accounts[buttonIndex]
             withHandler:^(NSData *responseData, NSError *error) {
                 if (responseData) {
                     NSString *responseStr = [[NSString alloc]
                                              initWithData:responseData
                                              encoding:NSUTF8StringEncoding];
                     
                     NSArray *parts = [responseStr
                                       componentsSeparatedByString:@"&"];
                     
                     for (NSString *part in parts){
                         if ([part rangeOfString:@"oauth_token="].location != NSNotFound){
                             //NSLog(@"part: %@",[[part componentsSeparatedByString:@"="] lastObject]);
                             //[_user setTwitterAuthToken:[[part componentsSeparatedByString:@"="] lastObject]];
                         } else if ([part rangeOfString:@"oauth_token_secret="].location != NSNotFound){
                             
                         } else if ([part rangeOfString:@"user_id="].location != NSNotFound){
                             //NSLog(@"part: %@",[[part componentsSeparatedByString:@"="] lastObject]);
                             //[_user setTwitterId:[[part componentsSeparatedByString:@"="] lastObject]];
                         } else {
                             //NSLog(@"part: %@",[[part componentsSeparatedByString:@"="] lastObject]);
                             //[_user setTwitterScreenName:[[part componentsSeparatedByString:@"="] lastObject]];
                         }
                     }
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         // NSLog(@"twitter user: %@",_user.twitterId);
                         // NSLog(@"twitter auth token: %@",_user.twitterAuthToken);
                         // NSLog(@"twitter screename: %@",_user.twitterScreenName);
                     });
                 }
                 else {
                     NSLog(@"Error!\n%@", [error localizedDescription]);
                 }
             }];
        }
    } else if ([actionSheet isMemberOfClass:[FDCustomSheet class]]) {
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                                   bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                                   bundle:nil];
        }
        FDRecommendViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RecommendView"];
        FDCustomSheet *customSheet = (FDCustomSheet*)actionSheet;
        [vc setPost:customSheet.post];
    
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Recommend on FOODIA"]) {
            //Recommending via FOODIA only
            [vc setPostingToFacebook:NO];
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Recommend via Facebook"]) {
            //Recommending via Facebook
            [vc setPostingToFacebook:YES];
            if ([FBSession.activeSession.permissions
                 indexOfObject:@"publish_actions"] == NSNotFound) {
                // No permissions found in session, ask for it
                [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                    if (!error) {
                        if ([FBSession.activeSession.permissions
                             indexOfObject:@"publish_actions"] != NSNotFound) {
                            // If permissions granted, go to the rec controller
                            [self.navigationController pushViewController:vc animated:YES];
                            
                        } else {
                            [self dismissViewControllerAnimated:YES completion:nil];
                            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we'll need your permission in order to post recommendations to Facebook." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
                        }
                    }
                }];
            } else if ([FBSession.activeSession.permissions
                        indexOfObject:@"publish_actions"] != NSNotFound) {
                [self.navigationController pushViewController:vc animated:YES];
            }
        } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send a Text"]) {
            //Recommending via text
            MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
            if ([MFMessageComposeViewController canSendText]){
                NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",customSheet.foodiaObject];
                viewController.messageComposeDelegate = self;
                [viewController setBody:textBody];
                [self presentModalViewController:viewController animated:YES];
            }
        } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send an Email"]) {
            //Recommending via mail
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = self;
                NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", customSheet.foodiaObject, customSheet.post.identifier];
                [controller setMessageBody:emailBody isHTML:YES];
                [controller setSubject:customSheet.foodiaObject];
                if (controller) [self presentModalViewController:controller animated:YES];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your recommendation. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
                [alert show];
            }
        } else {
            customSheet.post.recCount = [NSNumber numberWithInt:[customSheet.post.recCount integerValue] -1];
            [self.searchPosts replaceObjectAtIndex:customSheet.buttonTag withObject:customSheet.post];
            if (self.resultsTableView.numberOfSections < 2) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:customSheet.buttonTag inSection:0];
                [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                NSIndexPath *path = [NSIndexPath indexPathForRow:customSheet.buttonTag inSection:1];
                [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
            }
        }

    } else [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)refreshTwitterAccounts
{
    //  Get access to the user's Twitter account(s)
    [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSLog(@"You have access to the user's Twitter accounts");
                [self performReverseAuth:nil];
            }
            else {
                NSLog(@"You were not granted access to the Twitter accounts.");
                [self showTwitterSettings];
            }
        });
    }];
}

- (void)showTwitterSettings{
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    // Create the completion handler block.
    [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result)
     {
         [self dismissViewControllerAnimated:YES completion:^{
             [self performReverseAuth:nil];
         }];
     }];
    // Present the tweet composition view controller modally.
    [self presentViewController:tweetViewController animated:YES completion:nil];
    //tweetViewController.view.hidden = YES;
    for (UIView *view in tweetViewController.view.subviews){
        [view removeFromSuperview];
    }
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [_accountStore
                                  accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    
    ACAccountStoreRequestAccessCompletionHandler handler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [_accountStore accountsWithAccountType:twitterType];
        }
        
        block(granted);
    };
    
    //  This method changed in iOS6.  If the new version isn't available, fall
    //  back to the original (which means that we're running on iOS5+).
    if ([_accountStore
         respondsToSelector:@selector(requestAccessToAccountsWithType:
                                      options:
                                      completion:)]) {
             [_accountStore requestAccessToAccountsWithType:twitterType
                                                    options:nil
                                                 completion:handler];
         }
    else {
        [_accountStore requestAccessToAccountsWithType:twitterType
                                 withCompletionHandler:handler];
    }
}

- (void)performReverseAuth:(id)sender
{
    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
        self.twitterActionSheet = [[UIActionSheet alloc]
                                   initWithTitle:@"Choose an Account"
                                   delegate:self
                                   cancelButtonTitle:nil
                                   destructiveButtonTitle:nil
                                   otherButtonTitles:nil];
        
        for (ACAccount *acct in _accounts) {
            [self.twitterActionSheet addButtonWithTitle:acct.username];
        }
        
        [self.twitterActionSheet addButtonWithTitle:@"Cancel"];
        [self.twitterActionSheet setDestructiveButtonIndex:[_accounts count]];
        [self.twitterActionSheet showInView:self.view];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"No Accounts"
                              message:@"Please configure a Twitter "
                              "account in Settings.app"
                              delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)postToFacebook:(NSNotification*) notification{
    NSString *identifier = [notification.userInfo objectForKey:@"identifier"];
    [self performSelector:@selector(shareFacebookNonOpenGraph:) withObject:(NSString*)identifier afterDelay:0.2];
    
}

- (void)shareFacebookNonOpenGraph:(NSString*)identifier{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {

        SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        if (FDPost.userPost.foodiaObject.length){
            [facebookSheet setInitialText:[NSString stringWithFormat:@"I just posted about %@ on FOODIA",FDPost.userPost.foodiaObject]];
        } else {
            [facebookSheet setInitialText:[NSString stringWithFormat:@"I'm %@ on FOODIA",FDPost.userPost.category]];
        }
        
        if (FDPost.userPost.photoImage) [facebookSheet addImage:FDPost.userPost.photoImage];
        
        [facebookSheet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://posts.foodia.com/p/%@",identifier]]];
        
        [facebookSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
            
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    NSLog(@"Facebook Post Cancelled");
                    break;
                case SLComposeViewControllerResultDone:
                    NSLog(@"Facebook Post Sucessful");
                    break;
                    
                default:
                    if ([[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsTwitterActive]) [self showTwitter];
                    else if ([[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsInstagramActive]) [self showIg];
                    break;
            }
            
        }];
        
        [self presentViewController:facebookSheet animated:YES completion:nil];
    }
}

#pragma mark - LIKE section

// like or unlike the post
- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.searchPosts objectAtIndex:button.tag];
    if ([post isLikedByUser]) {
        [UIView animateWithDuration:.35 animations:^{
            [button setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
        }];
        [[FDAPIClient sharedClient] unlikePost:post
                                        detail:NO
                                       success:^(FDPost *newPost) {
                                           [self.searchPosts replaceObjectAtIndex:button.tag withObject:newPost];
                                           
                                           if (self.resultsTableView.numberOfSections < 2) {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                               [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                           } else {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                               [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                           }
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error.description);
                                           if (error.description){
                                               
                                           }
                                       }
         ];
        
    } else {
        [UIView animateWithDuration:.35 animations:^{
            [button setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
        }];
        [[FDAPIClient sharedClient] likePost:post
                                      detail:NO
                                     success:^(FDPost *newPost) {
                                         [self.searchPosts replaceObjectAtIndex:button.tag withObject:newPost];
                                         
                                         if (self.resultsTableView.numberOfSections == 1) {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                             [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         } /*else if (self.tableView.numberOfSections == 2) {
                                            NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                            }*/ else {
                                                NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                                [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                            }
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error.description);
                                     }
         ];
    }
}

#pragma mark - FDPostTableViewControllerDelegate Methods

- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPost:(FDPost *)post {
    [self.navigationController setNavigationBarHidden:NO];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

- (void)postTableViewController:(FDPostTableViewController *)controller didSelectPlace:(FDVenue *)place {
    [self.navigationController setNavigationBarHidden:NO];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self performSegueWithIdentifier:@"ShowPlace" sender:place];
}

#pragma mark - FDPostGridViewControllerDelegate Methods

- (void)postGridViewController:(FDPostGridViewController *)controller didSelectPost:(FDPost *)post {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
}

#pragma mark - Recommend Methods
- (void)recommend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.searchPosts objectAtIndex:button.tag];
    post.recCount = [NSNumber numberWithInt:[post.recCount integerValue] +1];
    [self.searchPosts replaceObjectAtIndex:button.tag withObject:post];
    if (self.resultsTableView.numberOfSections < 2) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
        [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
        [self.resultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    }
    FDCustomSheet *actionSheet;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA",@"Recommend via Facebook",@"Send a Text", @"Send an Email", nil];
    } else {
        actionSheet = [[FDCustomSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend on FOODIA",@"Send a Text", @"Send an Email", nil];
    }
    [actionSheet setFoodiaObject:post.foodiaObject];
    [actionSheet setPost:post];
    [actionSheet setButtonTag:button.tag];
    [actionSheet showInView:self.view];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
    } else if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your mail. Please try again..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSString *)stringWithDistance:(double)distance {
    BOOL isMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    NSString *format;
    
    if (isMetric) {
        if (distance < METERS_CUTOFF) {
            format = @"%@ m";
        } else {
            format = @"%@ km";
            distance = distance / 1000;
        }
    } else { // assume Imperial / U.S.
        distance = distance * METERS_TO_FEET;
        if (distance < FEET_CUTOFF) {
            format = @"%@ ft";
        } else {
            format = @"%@ mi";
            distance = distance / FEET_IN_MILES;
        }
    }
    return [NSString stringWithFormat:format, [self stringWithDouble:distance]];
}

// Return a string of the number to one decimal place and with commas & periods based on the locale.
- (NSString *)stringWithDouble:(double)value {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[NSLocale currentLocale]];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:1];
    return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
}

@end
