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
#import "TWAPIManager.h"
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWSignedRequest.h"
#import "FDAppDelegate.h"
#import <Accounts/Accounts.h>
#import "FDPostCell.h"
#import "Utilities.h"
#import "UIButton+WebCache.h"

@interface FDFeedViewController () <FDPostTableViewControllerDelegate, FDPostGridViewControllerDelegate, UIScrollViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

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
//@property (weak, nonatomic) IBOutlet UILabel *myPostsLabel;
@property (weak, nonatomic) IBOutlet UILabel *keepersLabel;
@property (weak, nonatomic) IBOutlet UILabel *nearbyLabel;
@property (weak, nonatomic) IBOutlet UILabel *recLabel;
@property (strong, nonatomic) UIImageView *logoImageView;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Looking at Feed View" timed:YES];
    self.trackedViewName = @"Initial Feed View";
    _accountStore = [[ACAccountStore alloc] init];
    _apiManager = [[TWAPIManager alloc] init];

    [(FDMenuViewController*)self.slidingViewController.underLeftViewController shrink];
    
    self.feedTableViewController        = [[FDFeedTableViewController alloc]        initWithDelegate:self];
    self.featuredGridViewController    = [[FDFeaturedGridViewController alloc]    initWithDelegate:self];
    //self.placesViewController      = [[FDPlacesViewController alloc] initWithDelegate:self];
    self.recommendedTableViewController = [[FDRecommendedTableViewController alloc] initWithDelegate:self];
    self.keepersViewController          = [[FDRecommendedTableViewController alloc]  initWithDelegate:self];

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
    
    self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blackLogo.png"]];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchPosts = [NSMutableArray array];
    self.resultsTableView.delegate = self;
    self.resultsTableView.dataSource = self;
    //customize the searchbar
    self.searchBar.placeholder = @"Search for food or drink";
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
            searchField.font = [UIFont fontWithName:kAvenirMedium size:14];
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
    
    UIImage *emptyBarButton = [UIImage imageNamed:@"emptyBarButton.png"];
    //[self.searchButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.menuButtonItem setBackgroundImage:emptyBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    _scrollView.clipsToBounds = NO;
	_scrollView.pagingEnabled = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [_scrollView setContentSize:CGSizeMake(352,78)];
    [self showFeatured];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.featuredLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.recLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.feedLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
        [self.keepersLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
    }
    
    UIView *testView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 88)];
    [testView addSubview:self.searchBar];
    [self.searchBar setTintColor:[UIColor whiteColor]];
    [self.searchBar setFrame:CGRectMake(0, -24, 200, 44)];
    [testView addSubview:self.logoImageView];
    [self.logoImageView setFrame:CGRectMake(60,29,80,31)];
    
    self.navigationItem.titleView = testView;
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
    [UIView animateWithDuration:.19 animations:^{
        [self.logoImageView setAlpha:0.0];
    }];
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionTransitionCurlDown animations:^{
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"up_arrow"]];
        [self.feedContainerView setFrame:CGRectMake(0,78,320,self.view.bounds.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(1.4*M_PI/180);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, 8);
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);
        clipView.transform = CGAffineTransformConcat(rotate, translation);
        self.searchBar.transform = CGAffineTransformMakeTranslation(0, 46);
        
        self.logoImageView.transform = CGAffineTransformMakeTranslation(0, 44);
        
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
    [self hideKeyboard];
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"down_arrow"]];
        [self.feedContainerView setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(0);
        CGAffineTransform translation = CGAffineTransformMakeTranslation(0, -85);
        _scrollView.transform = CGAffineTransformConcat(rotate, translation);
        clipView.transform = CGAffineTransformConcat(rotate, translation);
        self.clipViewBackground.transform = CGAffineTransformConcat(rotate, translation);
        self.searchBar.transform = CGAffineTransformIdentity;
        self.logoImageView.transform = CGAffineTransformIdentity;
        [self.logoImageView setAlpha:1.0];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self hideKeyboard];
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
        if (self.goToComment) [vc setShouldShowComment:YES];
        else [vc setShouldShowComment:NO];
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
    [self.recommendedTableViewController refresh];
    [self showPostViewController:self.recommendedTableViewController];
}

- (void)showNearby {
    //self.title = @"NEARBY";
    [self showPostViewController:self.placesViewController];
}

- (void)showKeepers {
    [self.keepersViewController setShouldShowKeepers:YES];
    [self.keepersViewController refresh];
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
    NSLog(@"reveal menu tapped");
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
    return self.searchPosts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 155;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *PostCellIdentifier = @"PostCell";
    FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
    }
    FDPost *post = [self.searchPosts objectAtIndex:indexPath.row];
    [cell configureForPost:post];
    
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
}


- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostCell class]]){
        FDPostCell *thisCell = (FDPostCell*)cell;
        //[thisCell.scrollView setContentOffset:CGPointMake(0,0) animated:NO];
        [UIView animateWithDuration:.25 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
            [thisCell.photoImageView setAlpha:0.0];
            [thisCell.posterButton setAlpha:0.0];
        }];
    }
}

- (void)comment:(id)sender{
    [self setGoToComment:YES];
    UIButton *button = (UIButton*)sender;
    [self performSegueWithIdentifier:@"ShowPost" sender:[self.searchPosts objectAtIndex:button.tag]];
}

- (void)didSelectRow:(id)sender {
    UIButton *button = (UIButton*)sender;
    [self setGoToComment:NO];
    [self performSegueWithIdentifier:@"ShowPost" sender:[self.searchPosts objectAtIndex:button.tag]];
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
    [UIView animateWithDuration:.25 animations:^{
        [self.resultsTableView setAlpha:.85];
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[searchBar resignFirstResponder];
    //[self hideKeyboard];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length){
        
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [[FDAPIClient sharedClient] getPostsForQuery:searchBar.text Success:^(id result) {
        self.searchPosts = result;
        [self.resultsTableView reloadData];
        [UIView animateWithDuration:.25 animations:^{
            [self.resultsTableView setAlpha:1.0];
        }];
        self.resultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    } failure:^(NSError *error) {
        NSLog(@"error from search method: %@",error.description);
    }];
    [searchBar endEditing:YES];
}

- (void)hideKeyboard {
    [self.searchBar endEditing:YES];
    [self.searchBar resignFirstResponder];
    [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.resultsTableView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.searchPosts removeAllObjects];
        [self.resultsTableView reloadData];
        [self.resultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
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
        [self performSelector:@selector(showIg) withObject:nil afterDelay:0.2];
    } else {
        UIAlertView *errorToShare = [[UIAlertView alloc] initWithTitle:@"Instagram unavailable " message:@"We were unable to connect to Instagram on this device" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [errorToShare show];
    }
}

-(void)showIg {
    [self.documentInteractionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:true];
}

- (void)postToTwitter:(NSNotification*)notification {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        NSString *postId = [notification.userInfo objectForKey:@"identifier"];
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
            self.tweetSheet = [SLComposeViewController
                                                   composeViewControllerForServiceType:SLServiceTypeTwitter];
            [self.tweetSheet setInitialText:[NSString stringWithFormat:@"%@ on #FOODIA | http://posts.foodia.com/p/%@", FDPost.userPost.foodiaObject, postId]];
            if (FDPost.userPost.photoImage){
                [self.tweetSheet addImage:FDPost.userPost.photoImage];
            }
            self.tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result) {
                switch (result) {
                    case TWTweetComposeViewControllerResultCancelled:
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                        //if posting to Instagram
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]) [self postToInstagram];
                    }
                        break;
                        
                    case TWTweetComposeViewControllerResultDone:
                    {
                        [self dismissViewControllerAnimated:YES completion:nil];
                        //if posting to Instagram
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsInstagramActive]) [self postToInstagram];
                    }
                        break;
                        
                    default:
                        break;
                }
            };
            
            [self performSelector:@selector(showTwitter) withObject:nil afterDelay:0.1];
            
        } else {
            [self refreshTwitterAccounts];
        }
    } else {
        UIAlertView *errorSharingTwitter = [[UIAlertView alloc] initWithTitle:@"Twitter unavailable" message:@"Sorry, but we weren't able to connect to your Twitter account on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [errorSharingTwitter show];
    }
}

-(void)showTwitter {
    [self presentViewController:self.tweetSheet animated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
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
         [self dismissViewControllerAnimated:YES completion:nil];
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
                              cancelButtonTitle:@"OK"
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
                    break;
            }
        }];
        
        [self presentViewController:facebookSheet animated:YES completion:nil];
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

@end
