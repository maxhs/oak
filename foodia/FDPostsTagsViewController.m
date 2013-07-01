//
//  FDPostsTagsViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/22/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPostsTagsViewController.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"
#import "FDPostCell.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDProfileViewController.h"
#import "UIButton+WebCache.h"
#import "Utilities.h"
#import "FDPostViewController.h"
#import "FDPlaceViewController.h"
#import "FDCustomSheet.h"
#import "FDLoginViewController.h"
#import "FDRecommendViewController.h"
#import <MessageUI/MessageUI.h>

@interface FDPostsTagsViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
    int rowToReload;
    BOOL goToComment;
    BOOL justLiked;
}
@property (nonatomic, strong) NSMutableArray *swipedCells;

@end

@implementation FDPostsTagsViewController

@synthesize swipedCells = _swipedCells;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.swipedCells = [NSMutableArray array];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellOpened" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipedCells:) name:@"CellClosed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTags) name:@"RefreshFeed" object:nil];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    goToComment = NO;
    [self loadTags];
    self.navigationItem.title = self.tagName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadTags {
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
    if (_universal){
        [[FDAPIClient sharedClient] getPostsForTag:self.tagName success:^(id result) {
            self.posts = result;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"error getting posts for tag: %@",error.description);
        }];
    } else {
        [[FDAPIClient sharedClient] getUserPostsForTag:self.tagName success:^(id result) {
            self.posts = result;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"Error gettings posts for user's tag: %@",error.description);
        }];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

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
                                           justLiked = NO;
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
                                         if (!justLiked) [newPost setLikeCount:[[NSNumber alloc] initWithInt:t]];
                                         justLiked = YES;
                                         
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 155;
}

-(void)profileTappedFromLikers:(id)sender {
    [self performSegueWithIdentifier:@"ShowProfileFromLikers" sender:sender];
}

-(void)profileTappedFromComment:(id)sender{
    [self performSegueWithIdentifier:@"ShowProfileFromComment" sender:sender];
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

- (void)swipedCells:(NSNotification*)notification {
    NSString *identifier = [notification.userInfo objectForKey:@"identifier"];
    if ([self.swipedCells indexOfObject:identifier] == NSNotFound){
        [self.swipedCells addObject:identifier];
    } else {
        [self.swipedCells removeObject:identifier];
    }
}

- (void)comment:(id)sender{
    goToComment = YES;
    UIButton *button = (UIButton*)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
    rowToReload = [self.posts indexOfObject:post];
}

- (void)didSelectRow:(id)sender {
    UIButton *button = (UIButton*)sender;
    FDPost *post = [self.posts objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ShowPost" sender:post];
    rowToReload = [self.posts indexOfObject:post];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowPost"]) {
        FDPostViewController *vc = segue.destinationViewController;
        if (goToComment) {[vc setShouldShowComment:YES];}
        else [vc setShouldShowComment:NO];
        [vc setPostIdentifier:[(FDPost *)sender identifier]];
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

- (void) updatePostNotification:(NSNotification *) notification {
    if (rowToReload != kRowToReloadInactive && self.posts.count){
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

-(void)showPlace:(UIButton*)button {
    if ([button.titleLabel.text isEqualToString:@"Home"] || [button.titleLabel.text isEqualToString:@"home"]) {
        if (self.universal){
            [[[UIAlertView alloc] initWithTitle:@"" message:@"We don't share information about anyone's home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Sorry, but we don't collect information about your home on FOODIA." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
        }
        
    } else {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        [self performSegueWithIdentifier:@"ShowPlace" sender:[self.posts objectAtIndex:button.tag]];
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
            [self presentModalViewController:viewController animated:YES];
        }
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send an Email"]) {
        //Recommending via mail
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", actionSheet.foodiaObject, actionSheet.post.identifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:actionSheet.foodiaObject];
            if (controller) [self presentModalViewController:controller animated:YES];
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



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
