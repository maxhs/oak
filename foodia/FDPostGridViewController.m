//
//  FDPostGridViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/1/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostGridViewController.h"
#import "FDRecord.h"
#import "FDUser.h"
#import "FDPostGridCell.h"
#import "EGORefreshTableHeaderView.h"
#import "AFNetworking.h"
#import "ECSlidingViewController.h"
#import "FDPostViewController.h"
#import "FDMenuViewController.h"

@interface FDPostGridViewController () <EGORefreshTableHeaderDelegate>
@property (nonatomic,strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic) BOOL isRefreshing;
@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *notificationRequestOperation;
@property CGFloat previousContentDelta;
@property (nonatomic, assign) int lastContentOffsetY;

@end

@implementation FDPostGridViewController

@synthesize posts = posts_;
@synthesize refreshHeaderView = refreshHeaderView_;
@synthesize isRefreshing = isRefreshing_;
@synthesize delegate = delegate_;
@synthesize feedRequestOperation = feedRequestOperation_;
@synthesize cellPosts;
@synthesize lastContentOffsetY = _lastContentOffsetY;
@synthesize previousContentDelta;
@synthesize notificationsPending;

- (id)initWithDelegate:(id)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        delegate_ = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isRefreshing_ = NO;
    self.tableView.rowHeight = [FDPostGridCell cellHeight];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.canLoadAdditionalPosts = YES;
    [self refresh];
    //[self loadFromCache];
    
    // set up the pull-to-refresh header
    if (refreshHeaderView_ == nil) {
        
        CGRect refreshFrame = CGRectMake(0.0f,
                                         0.0f - self.tableView.bounds.size.height,
                                         self.view.frame.size.width,
                                         self.tableView.bounds.size.height);
        EGORefreshTableHeaderView *view =
        [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame
                                          arrowImageName:@"FOODIA-refresh.png"
                                               textColor:[UIColor blackColor]];
        view.delegate = self;
        [self.tableView addSubview:view];
        refreshHeaderView_ = view;
        self.tableView.separatorColor = [UIColor clearColor];
        UITableViewCell *emptyCell = [self.tableView dequeueReusableCellWithIdentifier:@"emptyCell"];
        if (emptyCell == nil) {
            emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"emptyCell"];
            [emptyCell setBackgroundColor:[UIColor clearColor]];
            [emptyCell setFrame:CGRectMake(0,0,320,5)];
        }
        self.tableView.tableHeaderView = emptyCell;
    }
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getNotificationCount];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.feedRequestOperation = nil;
    [self saveCache];
}

- (void)saveCache {
    
}

- (void)loadFromCache {
 
}

-(void)getNotificationCount{
    self.notificationRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivityCountSuccess:^(NSString *notifications) {
        self.notificationsPending = [notifications integerValue];
        self.notificationRequestOperation = nil;
        //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    } failure:^(NSError *error) {
        self.notificationRequestOperation = nil;
        NSLog(@"Refreshing Failed");
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        if (notificationsPending == 0)
            return 0;
        else
            return 1;
    } else if (section == 1) {
        double amt = self.posts.count / 3;
        amt = ceil(amt);
        NSInteger tmp = amt;
        return tmp;
    } else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *NotificationCellIdentifier = @"NotificationCellIdenfitier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NotificationCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"NotificationCell" owner:self options:nil] lastObject];
        }
        [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(revealMenu) forControlEvents:UIControlEventTouchUpInside];
        if (notificationsPending == 1) {
            [((UIButton *)[cell viewWithTag:1]) setTitle:[NSString stringWithFormat:@"You have a new notification!"] forState:UIControlStateNormal];
        } else if (notificationsPending >1 ){
            [((UIButton *)[cell viewWithTag:1]) setTitle:[NSString stringWithFormat:@"You have %d new notifications!",notificationsPending] forState:UIControlStateNormal];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else {
    
    static NSString *PostGridCellIdentifier = @"PostGridCell";
    FDPostGridCell *cell = (FDPostGridCell *)[tableView dequeueReusableCellWithIdentifier:PostGridCellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostGridCell" owner:self options:nil];
        cell = (FDPostGridCell *)[nib objectAtIndex:0];
    }
    
    FDPost *post = [self.posts objectAtIndex:(indexPath.row*3)];
        UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [postButton setFrame:CGRectMake(5,0,100,100)];
        [postButton addTarget:self action:@selector(selectPost:) forControlEvents:UIControlEventTouchUpInside];
        postButton.tag=(indexPath.row*3);
        [cell addSubview:postButton];
    
    FDPost *post1 = [self.posts objectAtIndex:(indexPath.row*3)+1];
        UIButton *postButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [postButton1 setFrame:CGRectMake(110,0,100,100)];
        [postButton1 addTarget:self action:@selector(selectPost:) forControlEvents:UIControlEventTouchUpInside];
    postButton1.tag=(indexPath.row*3)+1;
        [cell addSubview:postButton1];
    
    FDPost *post2 = [self.posts objectAtIndex:(indexPath.row*3)+2];
        UIButton *postButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [postButton2 setFrame:CGRectMake(215,0,100,100)];
        [postButton2 addTarget:self action:@selector(selectPost:) forControlEvents:UIControlEventTouchUpInside];
    postButton2.tag=(indexPath.row*3)+2;
        [cell addSubview:postButton2];
    cellPosts = [NSMutableArray arrayWithObjects:post, post1, post2, nil];
    
    [cell configureForPost:cellPosts];
    return cell;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostGridCell class]]){
        FDPostGridCell *thisCell = (FDPostGridCell*)cell;
        [UIView animateWithDuration:.25 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
            [thisCell.photoBackground1 setAlpha:0.0];
            [thisCell.photoBackground2 setAlpha:0.0];
        }];
    }
}

-(void)selectPost: (id)sender {
    UIButton *button = (UIButton *) sender;
    FDPost *post = (FDPost*)[self.posts objectAtIndex:button.tag];
    NSDictionary *userInfo = @{@"identifier":[NSString stringWithFormat:@"%@",post.identifier]};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RowToReloadFromMenu" object:nil userInfo:userInfo];
    [self.delegate performSegueWithIdentifier:@"ShowPost" sender:post];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(FDPost *)post {
    if ([segue.identifier isEqualToString:@"ShowPost"]) {
        FDPostViewController *vcForPost = [segue destinationViewController];
        [vcForPost setPostIdentifier:post.identifier];
    }
}

- (void)revealMenu {
    [self.slidingViewController anchorTopViewTo:ECRight];
    [(FDMenuViewController *)self.slidingViewController.underLeftViewController refresh];
    int badgeCount = 0;
    // Resets the badge count when the view is opened
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.notificationsPending = 0;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

/*-(void)refreshPostWithId:(NSString *)postId withIndexPathRow:(NSInteger)indexPathRow {
    self.postRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getDetailsForPostWithIdentifier:postId success:^(FDPost *post) {
        //[self.posts insertObject:post atIndex:indexPathRow];
    } failure:^(NSError *error) {
    }];
    
    [self.postRequestOperation start];
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 46;
    else return 105;
}

#pragma mark - public methods

- (void)refresh {
    NSAssert(false, @"FDPostGridViewController's refresh method should not be called. Subclasses should override it.");
}

#pragma mark - private methods

- (void)reloadData {
    
    self.isRefreshing = NO;
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
}

- (void)didShowLastRow {
    NSLog(@"You've hit the last row");
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - [(UITableView*)scrollView rowHeight]*10) {
        [self didShowLastRow];
    }
    
    CGFloat prevDelta = self.previousContentDelta;
    CGFloat delta = scrollView.contentOffset.y - _lastContentOffsetY;
    if (delta > 0.f && prevDelta <= 0.f) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HideSlider" object:self];
    } else if (delta < -5.f && prevDelta >= 0.f) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"RevealSlider" object:self];
    }
    self.previousContentDelta = delta;
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastContentOffsetY = scrollView.contentOffset.y;
    self.previousContentDelta = 0.f;
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	self.isRefreshing = YES;
    [self refresh];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return self.isRefreshing; // should return if data source model is reloading
	
}

@end
