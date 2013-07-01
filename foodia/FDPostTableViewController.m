//
//  FDPostTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/21/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostTableViewController.h"
#import "FDUser.h"
#import "FDPostCell.h"
#import "AFNetworking.h"
#import "ECSlidingViewController.h"
#import "FDPostViewController.h"
#import "FDAppDelegate.h"
#import "FDPlaceViewController.h"
#import "FDProfileViewController.h"
#import "FDMenuViewController.h"
#import "Utilities.h"
#import <MessageUI/MessageUI.h>
#import "FDCustomSheet.h"
#import "Facebook.h"
#import "FDRecommendViewController.h"
#import "UIButton+WebCache.h"
#import "FDFeedViewController.h"

@interface FDPostTableViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    int rowToReload;
}

@property (nonatomic) BOOL isRefreshing;
@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) AFJSONRequestOperation *notificationRequestOperation;
@property CGFloat previousContentDelta;
@property (nonatomic, assign) int lastContentOffsetY;
@property BOOL justLiked;

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
@synthesize justLiked = _justLiked;
@synthesize swipedCells;

- (id)initWithDelegate:(id)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        delegate_ = delegate;
    }
    return self;
}

- (void)viewDidLoad {
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
                                          arrowImageName:@"FOODIA-refresh.png"
                                               textColor:[UIColor blackColor]];
        view.delegate = self;
        [self.tableView addSubview:view];
        refreshHeaderView_ = view;
        self.tableView.separatorColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    self.swipedCells = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellClosed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostNotification:) name:@"UpdatePostNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRowToReload:) name:@"RowToReloadFromMenu" object:nil];
}

- (void)setRowToReload:(NSNotification*) notification {
    NSString *postIdentifier = [notification.userInfo objectForKey:@"identifier"];
    for (FDPost *post in self.posts){
        if ([[NSString stringWithFormat:@"%@", post.identifier] isEqualToString:postIdentifier]){
            rowToReload = [self.posts indexOfObject:post];
            break;
        }
    }
    //post wasn't in this posts array, so make rowToReload inactive
    rowToReload = kRowToReloadInactive;
}

- (void)swipedCells:(NSNotification*)notification {
    NSString *identifier = [notification.userInfo objectForKey:@"identifier"];
    if ([self.swipedCells indexOfObject:identifier] == NSNotFound){
        [self.swipedCells addObject:identifier];
    } else {
        [self.swipedCells removeObject:identifier];
    }
}

-(void)getNotificationCount{
    if (self.notificationRequestOperation == nil) {
        self.notificationRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivityCountSuccess:^(NSString *notifications) {
            self.notificationsPending = [notifications integerValue];
            self.notificationRequestOperation = nil;
            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        } failure:^(NSError *error) {
            self.notificationRequestOperation = nil;
            NSLog(@"Refreshing Failed");
        }];
    }
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.justLiked = NO;
    [self getNotificationCount];
}

/*- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(!didLoadFromCache) {
        [self loadFromCache];
        didLoadFromCache = true;
    }
}

- (void)saveCache {
 
}

- (void)loadFromCache {
    
}
*/
// like or unlike the post
- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self.swipedCells addObject:post.identifier];
    if ([post isLikedByUser]) {
        [UIView animateWithDuration:.35 animations:^{
            [button setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
        }];
        [[FDAPIClient sharedClient] unlikePost:post
                                        detail:NO
                                       success:^(FDPost *newPost) {
                                           self.justLiked = NO;
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           if (self.tableView.numberOfSections < 2) {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                           } else {
                                               NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
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
                                         [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                         //conditionally change the like count number
                                         int t = [newPost.likeCount intValue] + 1;
                                         if (!self.justLiked) [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         self.justLiked = YES;
                                         
                                         if (self.tableView.numberOfSections == 1) {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         } else {
                                             NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
                                             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                         }
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error.description);
                                     }
         ];
    }
}

-(void)showPlace:(UIButton*)button {
    if ([button.titleLabel.text isEqualToString:@"Home"] || [button.titleLabel.text isEqualToString:@"home"]) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"We don't share information about anyone's home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
    } else {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self.delegate performSegueWithIdentifier:@"ShowPlace" sender:[self.posts objectAtIndex:button.tag]];
    }
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
    } else {
        return 1;
    }
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
    } else if (indexPath.section == 1) {
        static NSString *PostCellIdentifier = @"PostCell";
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:PostCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil] lastObject];
        }
        FDPost *post = [self.posts objectAtIndex:indexPath.row];
        [cell configureForPost:post];
        
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        cell.posterButton.titleLabel.text = post.user.userId;
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
        static NSString *FeedLoadingCellIdentifier = @"FeedLoadingCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FeedLoadingCellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FeedLoadingCell" owner:self options:nil] lastObject];
        }
        if (self.posts.count < 20) [cell setHidden:YES];
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FDPostCell class]] && !self.isRefreshing){
        FDPostCell *thisCell = (FDPostCell*)cell;
        [UIView animateWithDuration:.25 animations:^{
            [thisCell.photoBackground setAlpha:0.0];
            [thisCell.photoImageView setAlpha:0.0];
            [thisCell.posterButton setAlpha:0.0];
        }];
    }
}

- (void)recommend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    post.recCount = [NSNumber numberWithInt:[post.recCount integerValue] +1];
    [self.posts replaceObjectAtIndex:button.tag withObject:post];
    if (self.tableView.numberOfSections < 2) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:1];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
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

- (void) actionSheet:(FDCustomSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
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
            NSString *textBody = [NSString stringWithFormat:@"I just recommended %@ to you from FOODIA!\n Download the app now: itms-apps://itunes.com/apps/foodia",actionSheet.foodiaObject];
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self.delegate presentModalViewController:viewController animated:YES];
        }
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send an Email"]) {
        //Recommending via mail
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
    } else {
        actionSheet.post.recCount = [NSNumber numberWithInt:[actionSheet.post.recCount integerValue] -1];
        [self.posts replaceObjectAtIndex:actionSheet.buttonTag withObject:actionSheet.post];
        if (self.tableView.numberOfSections < 2) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:actionSheet.buttonTag inSection:0];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            NSIndexPath *path = [NSIndexPath indexPathForRow:actionSheet.buttonTag inSection:1];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
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

-(void)profileTappedFromLikers:(id)sender {
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self.delegate performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
}

-(void)showProfile:(UIButton*)button {
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

/*-(void)showSocial {
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
}*/

- (void) updatePostNotification:(NSNotification *) notification {
    if (rowToReload != kRowToReloadInactive){
        NSDictionary *userInfo = notification.userInfo;
        FDPost *postForReplacement = [userInfo objectForKey:@"post"];
        [self.posts removeObjectAtIndex:rowToReload];
        [self.posts insertObject:postForReplacement atIndex:rowToReload];
        NSIndexPath *indexPathToReload;
        if (self.tableView.numberOfSections > 1){
            indexPathToReload = [NSIndexPath indexPathForRow:rowToReload inSection:1];
        } else {
            indexPathToReload = [NSIndexPath indexPathForRow:rowToReload inSection:0];
        }
        NSArray* rowsToReload = [NSArray arrayWithObjects:indexPathToReload, nil];
        [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
    }
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

- (void)comment:(id)sender{
    FDFeedViewController *vc = self.delegate;
    [vc setGoToComment:YES];
    UIButton *button = (UIButton*)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self.delegate postTableViewController:self didSelectPost:post];
    rowToReload = [self.posts indexOfObject:post];
}

- (void)didSelectRow:(id)sender {
    UIButton *button = (UIButton*)sender;
    FDFeedViewController *vc = self.delegate;
    [vc setGoToComment:NO];
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self.delegate postTableViewController:self didSelectPost:post];
    rowToReload = [self.posts indexOfObject:post];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1) {
        if ([self.delegate respondsToSelector:@selector(postTableViewController:didSelectPost:)]) {
            [self.delegate postTableViewController:self didSelectPost:[self.posts objectAtIndex:indexPath.row]];
        } else if ([self.delegate respondsToSelector:@selector(postTableViewController:didSelectPlace:)]) {
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
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
    self.isRefreshing = NO;
}

- (void)didShowLastRow {
    NSLog(@"you've hit the last row");
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

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {	
	[self.refreshHeaderView egoRefreshScrollViewDidScroll:self.tableView];
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
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    self.isRefreshing = YES;
    if (self.notificationRequestOperation == nil) {
        self.notificationRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getActivityCountSuccess:^(NSString *notifications) {
            self.notificationsPending = [notifications integerValue];
            self.notificationRequestOperation = nil;
            //[self.tableView reloadData];
            [self refresh];
        } failure:^(NSError *error) {
            self.notificationRequestOperation = nil;
            NSLog(@"Refreshing Failed");
        }];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastContentOffsetY = scrollView.contentOffset.y;
    self.previousContentDelta = 0.f;
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return self.isRefreshing; // should return if data source model is reloading
}

@end
