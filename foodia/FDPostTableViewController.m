//
//  FDPostTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/21/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostTableViewController.h"
#import "FDNearbyTableViewController.h"
#import "FDUser.h"
#import "FDPostCell.h"
#import "AFNetworking.h"
#import "ECSlidingViewController.h"
#import "FDPostViewController.h"
#import "FDAppDelegate.h"
#import "FDPostNearbyCell.h"
#import "FDPlaceViewController.h"
#import "FDProfileViewController.h"
#import "FDMenuViewController.h"
#import "Utilities.h"
#import <MessageUI/MessageUI.h>
#import "FDCustomSheet.h"
#import "Facebook.h"
#import "FDRecommendViewController.h"

@interface FDPostTableViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic) BOOL isRefreshing;
@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *notificationRequestOperation;
@property CGFloat previousContentDelta;
@property (nonatomic, assign) int lastContentOffsetY;

@end

@implementation FDPostTableViewController

@synthesize posts = posts_;
@synthesize refreshHeaderView = refreshHeaderView_;
@synthesize isRefreshing = isRefreshing_;
@synthesize delegate = delegate_;
@synthesize feedRequestOperation = feedRequestOperation_;
@synthesize didLoadFromCache;
@synthesize notificationsPending;
@synthesize lastContentOffsetY = _lastContentOffsetY;
@synthesize previousContentDelta;


- (id)initWithDelegate:(id)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        delegate_ = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    notificationsPending = 0;
    [self getNotificationCount];
    self.tableView.showsVerticalScrollIndicator = NO;
    didLoadFromCache = false;
    [super viewDidLoad];
    isRefreshing_ = NO;
    self.tableView.rowHeight = [FDPostCell cellHeight];
    
    self.canLoadAdditionalPosts = YES;
    
    // set up the pull-to-refresh header
    if (refreshHeaderView_ == nil) {
        
        CGRect refreshFrame = CGRectMake(0.0f,
                                         0.0f - self.tableView.bounds.size.height,
                                         self.tableView.frame.size.width,
                                         self.tableView.bounds.size.height);
        EGORefreshTableHeaderView *view =
        [[EGORefreshTableHeaderView alloc] initWithFrame:refreshFrame
                                          arrowImageName:@"blackArrow.png"
                                               textColor:[UIColor blackColor]];
        view.delegate = self;
        [self.tableView addSubview:view];
        refreshHeaderView_ = view;
        self.tableView.separatorColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"RefreshFeed" object:nil];
    [self refresh];
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

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.feedRequestOperation cancel];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /*if(!didLoadFromCache) {
        [self loadFromCache];
        didLoadFromCache = true;
    }*/
}

- (void)saveCache {
    
}

- (void)loadFromCache {
    
}

// like or unlike the post
- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    
    if ([post isLikedByUser]) {
        [[FDAPIClient sharedClient] unlikePost:post
                                       success:^(FDPost *newPost) {
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSLog(@"self.tableView number of sections: %d",self.tableView.numberOfSections);
                                           if (self.tableView.numberOfSections < 2) {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                           } else {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                           }
                                       }
                                       failure:^(NSError *error) {
                                           NSLog(@"unlike failed! %@", error);
                                       }
         ];
        
    } else {
        [[FDAPIClient sharedClient] likePost:post
                                     success:^(FDPost *newPost) {
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         int t = [newPost.likeCount intValue] + 1;
                                         
                                         [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         if (self.tableView.numberOfSections == 1) {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         } /*else if (self.tableView.numberOfSections == 2) {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         }*/ else {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         }
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }
         ];
    }
}

-(void)showPlace: (id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    [self.delegate performSegueWithIdentifier:@"ShowPlace" sender:[self.posts objectAtIndex:button.tag]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        if(notificationsPending == 0)
            return 0;
        else
            return 1;
    } else if (section == 1) {
        return self.posts.count;
    } else if (self.posts.count == 0) {
        return 0;
    } else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *NotificationCellIdentifier = @"NotificationCellIdenfitier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NotificationCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationCell" owner:self options:nil];
            
            cell = (UITableViewCell *)[nib objectAtIndex:0];
        }
        [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(revealMenu) forControlEvents:UIControlEventTouchUpInside];
        if (notificationsPending == 1) {
            [((UIButton *)[cell viewWithTag:1]) setTitle:[NSString stringWithFormat:@"You have a new notification!"] forState:UIControlStateNormal];
        } else if (notificationsPending >1 ){
            [((UIButton *)[cell viewWithTag:1]) setTitle:[NSString stringWithFormat:@"You have %d new notifications!",notificationsPending] forState:UIControlStateNormal];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else if (indexPath.section == 1) {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell.photoImageView == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = cell.userId;
        [cell.posterButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
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
        
        UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recButton setFrame:CGRectMake(276,52,70,34)];
        [recButton addTarget:self action:@selector(recommend:) forControlEvents:UIControlEventTouchUpInside];
        [recButton setTitle:@"Rec" forState:UIControlStateNormal];
        recButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        recButton.layer.borderWidth = 1.0f;
        recButton.backgroundColor = [UIColor whiteColor];
        recButton.layer.cornerRadius = 17.0f;
        recButton.layer.shouldRasterize = YES;
        recButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [recButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [recButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        recButton.tag = indexPath.row;
        [cell.scrollView addSubview:recButton];

        UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [commentButton setFrame:CGRectMake(382,52,118,34)];
        commentButton.tag = indexPath.row;
        [commentButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        [commentButton setTitle:@"Add a comment..." forState:UIControlStateNormal];
        [commentButton setTitle:@"Nice!" forState:UIControlStateSelected];
        commentButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        commentButton.layer.borderWidth = 1.0f;
        commentButton.backgroundColor = [UIColor whiteColor];
        commentButton.layer.cornerRadius = 17.0f;
        commentButton.layer.shouldRasterize = YES;
        commentButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [commentButton.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
        [commentButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        
        [cell.scrollView addSubview:commentButton];

        return cell;
        
    } else {
        static NSString *FeedLoadingCellIdentifier = @"FeedLoadingCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedLoadingCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FeedLoadingCell" owner:self options:nil];
            cell = (FDPostCell *) [nib objectAtIndex:0];
        }
        
        return cell;
        /*NSLog(@"end cell section");
            static NSString *FeedEndCellIdenfitier = @"FeedEndCellIdenfitier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedEndCellIdenfitier];
            if (cell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FeedEndCell" owner:self options:nil];
                cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        [cell.contentView setHidden:YES];
        if(self.fewPosts = FALSE){
            NSLog(@"fewPosts is true from postTable");
            [((UIButton *)[cell viewWithTag:1]) addTarget:self action:@selector(showFeaturedPosts) forControlEvents:UIControlEventTouchUpInside];
            [((UIButton *)[cell viewWithTag:2]) addTarget:self action:@selector(showSocial) forControlEvents:UIControlEventTouchUpInside];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell setHidden:NO];
        }
        return cell;*/
    }
}



- (void)recommend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    FDCustomSheet *actionSheet = [[FDCustomSheet alloc] initWithTitle:@"I'm recommending something on FOODIA!" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Recommend via Facebook",@"Send a Text", @"Send an Email", nil];
    [actionSheet setFoodiaObject:post.foodiaObject];
    [actionSheet setPost:post];
    [actionSheet showInView:self.view];
}

- (void) actionSheet:(FDCustomSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"should be facebooking");
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                                   bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                                   bundle:nil];
        }
        FDRecommendViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RecommendView"];
        [vc setPost:actionSheet.post];
        
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
    } else if(buttonIndex == 1) {
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",actionSheet.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self.delegate presentModalViewController:viewController animated:YES];
        }
    } else if(buttonIndex == 2) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", actionSheet.foodiaObject, actionSheet.post.identifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:actionSheet.foodiaObject];
            if (controller) [self.delegate presentModalViewController:controller animated:YES];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your recommendation. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
            [alert show];
        }
    }
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

#pragma mark - Display likers

- (FDPostCell *)showLikers:(FDPostCell *)cell forPost:(FDPost *)post{
    NSDictionary *likers = post.likers;
    [cell.likersScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.likersScrollView.showsHorizontalScrollIndicator = NO;
    
    float imageSize = 34.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *liker in likers) {
        UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedLikeButtonRed.png"]];
        UIImageView *likerView = [[UIImageView alloc] initWithFrame:CGRectMake(((cell.likersScrollView.frame.origin.x)+((space+imageSize)*index)),(cell.likersScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *likerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
        likerButton.titleLabel.text = [liker objectForKey:@"facebook_id"];
        likerButton.titleLabel.hidden = YES;
        
        //[likerButton setTag: [[liker objectForKey:@"facebook_id"] integerValue]];
        [likerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
        [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[liker objectForKey:@"facebook_id"]]];
        //[likerView setUserId:[liker objectForKey:@"facebook_id"]];
        likerView.userInteractionEnabled = YES;
        likerView.clipsToBounds = YES;
        likerView.layer.cornerRadius = 5.0;
        //rasterize to improve performance
        likerView.layer.shouldRasterize = YES;
        likerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        likerView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
        heart.frame = CGRectMake((((space+imageSize)*index)+20),16,20,20);
        [likerButton setFrame:likerView.frame];
        heart.clipsToBounds = NO;
        [cell.likersScrollView addSubview:likerView];
        [cell.likersScrollView addSubview:heart];
        [cell.likersScrollView addSubview:likerButton];
        index++;
    }
    [cell.likersScrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    return cell;
}

-(void)profileTappedFromLikers:(id)sender {
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
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

-(void)showSocial {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ShowSocial"
     object:self];
}
-(void)showFeaturedPosts {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ShowFeatured"
     object:self];
}
-(void)showActivity {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ShowActivity"
     object:self];
}

/*-(void)refreshPostWithId:(NSString *)postId withIndexPathRow:(NSInteger)indexPathRow {
    self.postRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getDetailsForPostWithIdentifier:postId success:^(FDPost *post) {
    
    } failure:^(NSError *error) {
    
    }];
    [self.postRequestOperation start];
}*/

- (void) updatePostNotification:(NSNotification *) notification {
    /*NSDictionary *userInfo = notification.userInfo;
    [self setIsLikedByUsers:[userInfo objectForKey:@"likers"] withLikeCount:[((NSNumber *)[userInfo objectForKey:@"likeCount"]) integerValue] forPostWithId:(NSString *)[userInfo objectForKey:@"postId"]];*/
}

-(void)setIsLikedByUsers:(NSDictionary *)newLikers withLikeCount:(NSInteger)newLikeCount forPostWithId:(NSString *)postId {
    [[self.posts objectAtIndex:self.tableView.indexPathForSelectedRow.row] setLikeCount:[NSNumber numberWithInteger:newLikeCount]];
    [[self.posts objectAtIndex:self.tableView.indexPathForSelectedRow.row] setLikers:newLikers];
    [self.tableView reloadData];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 44;
    else return 155;
}

- (void)didSelectRow:(id)sender {
    UIButton *button = (UIButton*)sender;
    [self.delegate postTableViewController:self didSelectPost:[self.posts objectAtIndex:button.tag]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1) {
        if ([self.delegate respondsToSelector:@selector(postTableViewController:didSelectPost:)]) {
            [self.delegate postTableViewController:self didSelectPost:[self.posts objectAtIndex:indexPath.row]];
        } else if ([self.delegate respondsToSelector:@selector(postTableViewController:didSelectPlace::)]) {
            [self.delegate postTableViewController:self didSelectPlace:[self.posts objectAtIndex:indexPath.row]];
        }
    }
}

#pragma mark - public methods

- (void)refresh {
    NSAssert(false, @"FDPostTableViewController's refresh method should not be called. Subclasses should override it.");
}

#pragma mark - private methods

- (void)reloadData {
    self.isRefreshing = NO;
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
}

- (void)didShowLastRow {
    NSLog(@"you've hit the last row");
}

- (void)revealMenu {
    [self.slidingViewController anchorTopViewTo:ECRight];
    NSLog(@"just revealed the menu from the notification button");
    [(FDMenuViewController *)self.slidingViewController.underLeftViewController refresh];
    int badgeCount = 0;
    // Resets the badge count when the view is opened
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.notificationsPending = 0;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	[self.refreshHeaderView egoRefreshScrollViewDidScroll:self.tableView];
    
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - [(UITableView*)scrollView rowHeight]*5) {
        [self didShowLastRow];
    }
    
    CGFloat prevDelta = self.previousContentDelta;
    CGFloat delta = scrollView.contentOffset.y - _lastContentOffsetY;
    if (delta > 0.f && prevDelta <= 0.f) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HideSlider" object:self];
    } else if (delta < 0.f && prevDelta >= 0.f) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RevealSlider" object:self];
    }
    self.previousContentDelta = delta;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    self.isRefreshing = YES;
    self.notificationRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivityCountSuccess:^(NSString *notifications) {
        self.notificationsPending = [notifications integerValue];
        self.notificationRequestOperation = nil;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        self.notificationRequestOperation = nil;
        NSLog(@"Refreshing Failed");
    }];
    [self.tableView reloadData];
    [self refresh];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastContentOffsetY = scrollView.contentOffset.y;
    self.previousContentDelta = 0.f;
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return self.isRefreshing; // should return if data source model is reloading
}

@end
