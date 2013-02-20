//
//  FDProfileViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/16/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDProfileViewController.h"
#import "FDProfileNavigationController.h"
#import "FDAPIClient.h"
#import "FDAppDelegate.h"
#import "FDPost.h"
#import "Utilities.h"
#import "FDPostCell.h"
#import "FDPostTableViewController.h"
#import "FDPostViewController.h"
#import "FDPeopleTableViewController.h"
#import "Constants.h"
#import "FDUserCell.h"
#import "FDProfileMapViewController.h"
#import "Facebook.h"
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import "FDRecommendViewController.h"
#import "FDCustomSheet.h"
#import "FDPlaceViewController.h"
@interface FDProfileViewController() <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic) BOOL canLoadMore;
@property int tableViewHeight;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *activateSearchButton;
@property (nonatomic, weak) IBOutlet UIView *profileDetailsContainerView;
@property int *postListHeight;

@end

@implementation FDProfileViewController
@synthesize profileButton;
@synthesize postList;
//@synthesize posts;
@synthesize user;
@synthesize userId;
@synthesize profileContainerView;
@synthesize userNameLabel;
//@synthesize postButton, followersButton, followingButton;
//@synthesize inviteRequest;
@synthesize inactiveLabel;
@synthesize postCountLabel, followingCountLabel, followerCountLabel;
@synthesize feedRequestOperation;
@synthesize detailsRequestOperation;
@synthesize followers;
@synthesize following;
@synthesize currTab;
@synthesize currButton;
@synthesize canLoadMore;
@synthesize tableViewHeight;

- (void)initWithUserId:(NSString *)uid {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.userId = uid;
    self.canLoadMore = YES;
    self.detailsRequestOperation = [[FDAPIClient sharedClient] getProfileDetails:uid success:^(NSDictionary *result) {
        [profileButton setUserId:self.userId];
        currTab = 0;
        currButton = @"follow";
        self.followers = [NSArray array];
        self.following = [NSArray array];
        [self loadPosts:self.userId];
        [self.postList setHidden:false];
        [self.inactiveLabel setHidden:true];
        self.userNameLabel.text = [result objectForKey:@"name"];
        [self.userNameLabel setTextColor:[UIColor blackColor]];
        if([[NSString stringWithFormat:@"%@",[result objectForKey:@"active"]] isEqualToString:@"1"]) {
            self.postCountLabel.text = [[result objectForKey:@"posts_count"] stringValue];
            self.followingCountLabel.text = [[result objectForKey:@"following_count"] stringValue];
            self.followerCountLabel.text = [[result objectForKey:@"followers_count"] stringValue];
            if([[NSString stringWithFormat:@"%@",[result objectForKey:@"following"]] isEqualToString:@"1"]) {
                [self.socialButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor lightGrayColor]];
                [self.socialButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
                currButton = @"following";
            } else {
                [self.socialButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
                [self.socialButton.titleLabel setTextColor:[UIColor redColor]];
                [self.socialButton.layer setBorderColor:[UIColor redColor].CGColor];
                currButton = @"follow";
            }
            self.followers = [result objectForKey:@"followers_arr"];
            self.following = [result objectForKey:@"following_arr"];
            [self.postList reloadData];
        
        } else {
            [self.socialButton setTitle:@"INVITE" forState:UIControlStateNormal];
            [self.postList setHidden:true];
            [self.inactiveLabel setHidden:false];
            currButton = @"invite";
        }
    } failure:^(NSError *error) {

    }];
    
    self.user = nil;
    
}

-(IBAction)followButtonTapped {
    if([currButton isEqualToString:@"follow"]) {
        NSLog(@"Follow Tapped...");
        (void)[[FDAPIClient sharedClient] followUser:self.userId];
        //temporarily change follow number
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter+=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d",followerCounter];
        self.currButton = @"following";
        [self.socialButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else if([currButton isEqualToString:@"following"]) {
        NSLog(@"unfollowing Tapped...");
        int followerCounter;
        followerCounter = [followerCountLabel.text integerValue];
        followerCounter-=1;
        followerCountLabel.text = [NSString stringWithFormat:@"%d",followerCounter];
        
        (void)[[FDAPIClient sharedClient] unfollowUser:self.userId];
        
        self.currButton = @"follow";
        [self.socialButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    } else if([currButton isEqualToString:@"invite"]) {
        NSLog(@"Invite Tapped...");
        [self inviteUser:self.userId];
        [self.socialButton setTitle:@"INVITED" forState:UIControlStateNormal];
        [self.socialButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    //if (!self.userId)[self initWithUserId:[[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookID"]];
    currTab = 0;
    [self.navigationController setNavigationBarHidden:NO];
    self.mapView.layer.cornerRadius = 5.0f;
    self.mapView.clipsToBounds = YES;
    self.filteredPosts = [NSMutableArray array];
    self.followers = [NSArray array];
    self.following = [NSArray array];
    [self.postList setDataSource:self];
    [self.postList setDelegate:self];
    self.makingButton.layer.cornerRadius = 17.0;
    self.eatingButton.layer.cornerRadius = 17.0;
    self.drinkingButton.layer.cornerRadius = 17.0;
    self.shoppingButton.layer.cornerRadius = 17.0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followCreated:) name:kNotificationFollowCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followDestroyed:) name:kNotificationFollowDestroyed object:nil];
    self.tableViewHeight = self.postList.frame.size.height;
    [self.searchDisplayController setDelegate:self];
    [self.searchDisplayController.searchBar setDelegate:self];
    self.searchDisplayController.searchBar.placeholder = @"Search for food, friends, places, etc";
    for (UIView *view in self.searchDisplayController.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    //set custom font in searchBar
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        }
    }
    self.searchDisplayController.searchBar.showsScopeBar = YES;
    self.searchDisplayController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"ALL",@"Eat",@"Drink",@"Make",@"Shop",nil];
    self.searchDisplayController.searchBar.scopeBarBackgroundImage = [UIImage imageNamed:@"newFoodiaHeader.png"];
    self.socialButton.layer.borderWidth = 1.0f;
    self.socialButton.layer.cornerRadius = 16.0f;
    self.socialButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [TestFlight passCheckpoint:@"Passed Profile checkpoint"];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuBarButtonImage.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(revealMenu:)];
    if (self.navigationController.navigationBar.backItem == nil) {
        self.navigationItem.leftBarButtonItem = menuButton;
    }
}

- (void)followCreated:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:YES] forKey:@"is_followed_by_user?"];
    }
}

- (void)followDestroyed:(NSNotification *)notification {
    if ([self.userId isEqualToString:notification.object]) {
        [self.user setObject:[NSNumber numberWithBool:NO] forKey:@"is_followed_by_user?"];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView != self.searchDisplayController.searchResultsTableView) return 3;
    else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredPosts.count;
    } else if(section == 0 && currTab == 0) {
        return self.posts.count;
    } else if(section == 1 && currTab == 1 && self.followers.count > 0 && self.following.count > 0) {
        return self.followers.count;
    } else if(section == 2 && currTab == 2 && self.following.count > 0 && self.followers.count > 0) {
        return self.following.count;
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) return 155;
    else return 44;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        //end of loading
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }
}

-(void)loadPosts:(NSString *)uid{
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getFeedForProfile:uid success:^(NSMutableArray *newPosts) {
        self.posts = newPosts;
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error) {
        self.feedRequestOperation = nil;
        [self.postList reloadData];
    }];
    if (self.posts.count == 0) [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        FDPostCell *cell = (FDPostCell *)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPostCell" owner:self options:nil];
            cell = (FDPostCell *)[nib objectAtIndex:0];
        }
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            FDPost *post = [self.filteredPosts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
        } else {
            FDPost *post = [self.posts objectAtIndex:indexPath.row];
            [cell configureForPost:post];
            cell = [self showLikers:cell forPost:post];
            [cell bringSubviewToFront:cell.likersScrollView];
            
            cell.detailPhotoButton.tag = [post.identifier integerValue];
            [cell.detailPhotoButton addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
            
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
            commentButton.tag = [post.identifier integerValue];
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
            
            //capture touch event to show user place map
            if (post.locationName.length){
                [cell.locationButton setHidden:NO];
                [cell.locationButton addTarget:self action:@selector(showPlace:) forControlEvents:UIControlEventTouchUpInside];
                cell.locationButton.tag = indexPath.row;
            }
        }
        [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.likeButton.tag = indexPath.row;
        
        return cell;
        
    } else if(indexPath.section == 1 && tableView != self.searchDisplayController.searchResultsTableView) {
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil];
            cell = (FDUserCell *)[nib objectAtIndex:0];
        }
        cell.nameLabel.text = [[self.followers objectAtIndex:indexPath.row] objectForKey:@"name"];
        [cell setFacebookId:[[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        [cell.button setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        peopleButton.tag = [[[self.followers objectAtIndex:indexPath.row] objectForKey:@"fbid"] integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.imageFrame];
        return cell;
    } else if(indexPath.section == 2 && tableView != self.searchDisplayController.searchResultsTableView){
        FDUserCell *cell = (FDUserCell *)[tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:self options:nil];
            cell = (FDUserCell *)[nib objectAtIndex:0];
        }
        cell.nameLabel.text = [[self.following objectAtIndex:indexPath.row] objectForKey:@"name"];
        [cell setFacebookId:[[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"]];
        [cell.button setHidden:true];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *peopleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell addSubview:peopleButton];
        peopleButton.tag = [[[self.following objectAtIndex:indexPath.row] objectForKey:@"fbid"] integerValue];
        [peopleButton addTarget:self action:@selector(profileTappedFromProfile:) forControlEvents:UIControlEventTouchUpInside];
        [peopleButton setFrame:cell.imageFrame];
        return cell;
    } else {
        UITableViewCell *emptyCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        emptyCell.userInteractionEnabled = NO;
        return emptyCell;
    }
}

- (void)didSelectRow:(id)sender {
    //UIButton *button = (UIButton*)sender;
    [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:sender];
}

-(void)showPlace:(id)sender {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    UIButton *button = (UIButton *) sender;
    [self performSegueWithIdentifier:@"ShowPlace" sender:[self.posts objectAtIndex:button.tag]];
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
            [self presentViewController:viewController animated:YES completion:nil];
        }
    } else if(buttonIndex == 2) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"I just recommended %@ to you on FOODIA! Take a look: http://posts.foodia.com/p/%@ <br><br> Or <a href='http://itunes.com/apps/foodia'>download the app now!</a>", actionSheet.foodiaObject, actionSheet.post.identifier];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:actionSheet.foodiaObject];
            if (controller) [self presentViewController:controller animated:YES completion:nil];
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
    
    float imageSize = 36.0;
    float space = 6.0;
    int index = 0;
    
    for (NSDictionary *liker in likers) {
        UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feedLikeButtonRed.png"]];
        UIImageView *likerView = [[UIImageView alloc] initWithFrame:CGRectMake(((cell.likersScrollView.frame.origin.x)+((space+imageSize)*index)),(cell.likersScrollView.frame.origin.y), imageSize, imageSize)];
        UIButton *likerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        //passing liker facebook id as a string instead of NSNumber so that it can hold more data. crafty.
        likerButton.titleLabel.text = [liker objectForKey:@"facebook_id"];
        likerButton.titleLabel.hidden = YES;
        
        [likerButton addTarget:self action:@selector(profileTappedFromLikers:) forControlEvents:UIControlEventTouchUpInside];
        [likerView setImageWithURL:[Utilities profileImageURLForFacebookID:[liker objectForKey:@"facebook_id"]]];
        likerView.userInteractionEnabled = YES;
        likerView.clipsToBounds = YES;
        likerView.layer.cornerRadius = 5.0;
        likerView.frame = CGRectMake(((space+imageSize)*index),0,imageSize, imageSize);
        heart.frame = CGRectMake((((space+imageSize)*index)+22),18,20,20);
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

-(void)profileTappedFromProfile:(id)sender {
    UIButton *button = (UIButton *) sender;
    [self initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowProfileFromProfile"]) {
        UIButton *button = (UIButton *) sender;
        FDProfileViewController *profileVC = segue.destinationViewController;
        [profileVC initWithUserId:[NSString stringWithFormat:@"%d",button.tag]];
    } else if ([segue.identifier isEqualToString:@"ShowPostFromProfile"]) {
        FDPostViewController *vc = segue.destinationViewController;
        if ([sender isMemberOfClass:[UIButton class]]){
            UIButton *button = (UIButton *) sender;
            [vc setPostIdentifier:[NSString stringWithFormat:@"%d",button.tag]];
        } else {
            FDPost *post = (FDPost *) sender;
            [vc setPostIdentifier:post.identifier];
        }
    } else if ([segue.identifier isEqualToString:@"ShowProfileMap"]) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
        FDProfileMapViewController *vc = segue.destinationViewController;
        [vc setUid:self.userId];
    } else if ([segue.identifier isEqualToString:@"ShowPlace"]){
        FDPlaceViewController *placeView = [segue destinationViewController];
        FDPost *post = (FDPost *) sender;
        [placeView setVenueId:post.foursquareid];
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - [(UITableView *)scrollView rowHeight]*10) {
        scrollView = nil;
        [self didShowLastRow];
    }
}

- (IBAction)showFollowers:(id)sender {
    self.currTab = 1;
    [self resetCategoryButtons];
    [self.postList reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        FDPost *selectedPost = (FDPost *)[self.filteredPosts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    } else if(indexPath.section == 0) {
        FDPost *selectedPost = (FDPost *)[self.posts objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowPostFromProfile" sender:selectedPost];
    }
}

- (IBAction)showFollowing:(id)sender {
    self.currTab = 2;
    [self resetCategoryButtons];
    [self.postList reloadData];
}

- (IBAction)showPosts:(id)sender {
    self.currTab = 0;
    self.canLoadMore = YES;
    [self resetCategoryButtons];
    //[self.postList reloadData];
    [self loadPosts:self.userId];
}

-(void)inviteUser:(NSString *)who {
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions", nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (!error) {
                // If permissions granted, publish the story
                [self inviteUserFb:who];
            }
        }];
    } else {
        // If permissions present, publish the story
        [self inviteUserFb:who];
    }
}

-(void)inviteUserFb:(NSString *)who {
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:self initialText:@"Download FOODIA. Spend less time with your phone and more time with your food." image:[UIImage imageNamed:@"blackLogo.png"] url:[NSURL URLWithString:@"http://www.foodia.com"] handler:^(FBNativeDialogResult result, NSError *error) {
        
        // Only show the error if it is not due to the dialog
        // not being supporte, i.e. code = 7, otherwise ignore
        // because our fallback will show the share view controller.
        if (error && [error code] == 7) {
            return;
            NSLog(@"there was an error code 7");
        }
        NSString *alertText = @"";
        if (error) {
            /*alertText = [NSString stringWithFormat:
             @"error: domain = %@, code = %d",
             error.domain, error.code];*/
        } else if (result == FBNativeDialogResultSucceeded) {
            alertText = @"Good going telling a friend about FOODIA! Why not tell another?";
        }
        if (![alertText isEqualToString:@""]) {
            // Show the result in an alert
            [[[UIAlertView alloc] initWithTitle:@"Thanks!"
                                        message:alertText
                                       delegate:self
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil] show];
        }
    }];
    
    if (!displayedNativeDialog) {

    }
}


- (void)likeButtonTapped:(UIButton *)button {
    FDPost *post = [self.posts objectAtIndex:button.tag];
    
    if ([post isLikedByUser]) {
        [[FDAPIClient sharedClient] unlikePost:post
                                       success:^(FDPost *newPost) {
                                           [self.posts replaceObjectAtIndex:button.tag withObject:newPost];
                                           NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                           [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
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
                                         NSIndexPath *path = [NSIndexPath indexPathForRow:button.tag inSection:0];
                                         [self.postList reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
                                     } failure:^(NSError *error) {
                                         NSLog(@"like failed! %@", error);
                                     }
         ];
    }
}

- (void)loadAdditionalPosts{
    if (self.canLoadMore == YES){
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedBefore:self.posts.lastObject forProfile:self.userId success:^(NSMutableArray *morePosts) {
        if (morePosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            [self.posts addObjectsFromArray:morePosts];
            NSLog(@"this is self.posts.count after additions: %d", self.posts.count);
            if (self.posts.count < [self.postCountLabel.text integerValue] && self.canLoadMore == YES)[self loadAdditionalPosts];
            [self.postList reloadData];
        }
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
        NSLog(@"adding more profile posts has failed");
    }];
    } else NSLog(@"can't load more");
}

- (void) didShowLastRow {
    if (self.posts.count && self.feedRequestOperation == nil && canLoadMore){
        [self loadAdditionalPosts];
    }
}

- (IBAction)getFeedForEating {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    [self resetCategoryButtons];
    //[self.eatingButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor lightGrayColor]];

    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Eating" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

- (IBAction)getFeedForDrinking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    [self resetCategoryButtons];
    //[self.drinkingButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor lightGrayColor]];

    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Drinking" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (IBAction)getFeedForMaking {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.canLoadMore = NO;
    self.currTab = 0;
    [self resetCategoryButtons];
    //[self.makingButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor lightGrayColor]];
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Making" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}
- (IBAction)getFeedForShopping {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [self resetCategoryButtons];
    //[self.shoppingButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor lightGrayColor]];
    self.canLoadMore = NO;
    self.currTab = 0;
    self.feedRequestOperation = (AFJSONRequestOperation *)[[FDAPIClient sharedClient] getProfileFeedForCategory:@"Shopping" forProfile:self.userId success:^(NSMutableArray *categoryPosts) {
        if (categoryPosts.count == 0){
            self.canLoadMore = NO;
            [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        } else {
            self.posts = categoryPosts;
        }
        [self.postList reloadData];
        self.feedRequestOperation = nil;
    } failure:^(NSError *error){
        self.feedRequestOperation = nil;
    }];
}

-(void) resetCategoryButtons {
    [self.shoppingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor clearColor]];
    [self.makingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor clearColor]];
    [self.eatingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor clearColor]];
    [self.drinkingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor clearColor]];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.postList setFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
    [self.postList setHidden:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.searchDisplayController.searchBar setFrame:CGRectMake(0,0,320,44)];
        self.profileButton.alpha = 0.0f;
        self.makingButton.alpha = 0.0f;
        self.shoppingButton.alpha = 0.0f;
        self.drinkingButton.alpha = 0.0f;
        self.eatingButton.alpha = 0.0f;
        self.profileDetailsContainerView.alpha = 0.0f;
    }];
    
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.filteredPosts removeAllObjects];
    [self.postList reloadData];
    [self.postList setHidden:NO];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.searchDisplayController.searchBar setFrame:CGRectMake(0,-44,320,44)];
        [self.searchDisplayController.searchBar setAlpha:0.0f];
        self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
        self.profileButton.alpha = 1.0f;
        self.makingButton.alpha = 1.0f;
        self.shoppingButton.alpha = 1.0f;
        self.drinkingButton.alpha = 1.0f;
        self.eatingButton.alpha = 1.0f;
        self.profileDetailsContainerView.alpha = 1.0f;
        [self.postList setFrame:CGRectMake(0,164,320,self.tableViewHeight)];
    }];
}

-(IBAction)activateSearch {
    [self loadAdditionalPosts];
    if (self.searchDisplayController.searchBar.alpha == 0.0f){
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.searchDisplayController.searchBar.alpha = 1.0f;
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0,0,320,44)];
            self.profileDetailsContainerView.frame = CGRectMake(0,44,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 0.0f;
            self.shoppingButton.alpha = 0.0f;
            self.drinkingButton.alpha = 0.0f;
            self.eatingButton.alpha = 0.0f;
            self.buttonBackground.alpha = 0.0f;
        }];
    } else {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.searchDisplayController.searchBar.alpha = 0.0f;
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0,-44,320,44)];
            self.profileDetailsContainerView.frame = CGRectMake(0,0,320,self.profileDetailsContainerView.bounds.size.height);
            self.makingButton.alpha = 1.0f;
            self.shoppingButton.alpha = 1.0f;
            self.drinkingButton.alpha = 1.0f;
            self.eatingButton.alpha = 1.0f;
            self.buttonBackground.alpha = 1.0f;
        }];
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)originalScope
{
    //Update the filtered array based on the search text and scope.
    [self.filteredPosts removeAllObjects];
    NSString *scope;
    if ([originalScope isEqualToString:@"Make"]) scope = @"Making";
    else scope = originalScope;
    NSLog(@"current scope: %@", scope);
    // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    if ([scope isEqualToString:@"ALL"]){
        for (FDPost *post in self.posts){
            NSString *combinedSearchBase = [NSString stringWithFormat:@"%@ %@", post.socialString, post.caption ];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:combinedSearchBase]) {
                [self.filteredPosts addObject:post];
            }
        }
    } else {
        for (FDPost *post in self.posts){
            NSMutableArray *predicateParts = [NSMutableArray arrayWithObjects:[NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText],[NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", scope],nil];
            NSPredicate *combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateParts];
            NSLog(@"predicate parts: %@",predicateParts);
            NSLog(@"combinedPredicate: %@", combinedPredicate);
            NSString *combinedSearchBase = [NSString stringWithFormat:@"%@ %@", post.socialString, post.caption ];
            if([combinedPredicate evaluateWithObject:combinedSearchBase]) {
                [self.filteredPosts addObject:post];
            }
        }
    }
}
#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.feedRequestOperation = nil;
    [super viewWillDisappear:animated];
}

@end
