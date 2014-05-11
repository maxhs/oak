//
//  FDPeopleTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/11/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPeopleTableViewController.h"
#import "FDAPIClient.h"
#import "FDCache.h"
#import "Utilities.h"
#import "FDUser.h"
#import "FDProfileViewController.h"
#import "Facebook.h"
#import "FDSocialViewController.h"
#import <MessageUI/MessageUI.h>

@interface FDPeopleTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    NSMutableArray *personQueryResults;
    BOOL isSearching;
}
@property (nonatomic, strong) NSArray *follows;
@property (nonatomic, strong) NSArray *followers;
@property (nonatomic, strong) AFJSONRequestOperation *followRequestOperation;
@property (nonatomic, strong) AFJSONRequestOperation *peopleRequestOperation;
@property (nonatomic, strong) NSString *facebookId;
@end

@implementation FDPeopleTableViewController

@synthesize delegate = delegate_;
@synthesize followers = _followers;
@synthesize follows = _follows;
@synthesize followRequestOperation;
@synthesize peopleRequestOperation;
@synthesize facebookId = _facebookId;
@synthesize people = _people;
@synthesize filteredPeople = _filteredPeople;

- (id)initWithDelegate:(id)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        delegate_ = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.filteredPeople) self.filteredPeople = [NSMutableArray array];
    if ([self isKindOfClass:[FDSocialViewController class]]) {
        [self getFollows];
    } else {
        [self loadPeople];
    }
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

/*- (void)getFollowers {
    self.followRequestOperation = [[FDAPIClient sharedClient] getFollowers:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] success:^(id result) {
        self.followers = result;
    } failure:^(NSError *error) {
        
    }];
}*/

- (void)getFollows {
    self.followRequestOperation = [[FDAPIClient sharedClient] getFollowingIds:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] success:^(id result) {
        self.follows = result;
        [self loadPeople];
    } failure:^(NSError *error) {
        NSLog(@"get follows error: %@", error.description);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // get the cached people list
    //self.people = [FDCache getCachedPeople];
    //self.filteredPeople = [[FDCache getCachedPeople] mutableCopy];
    //[self.tableView reloadData];
    
    //set custom font in searchBar
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kHelveticaNeueThin size:15];
        }
    }
}

-(void)loadPeople{
    // if the list is stale, update it
    //if ([FDCache isPeopleCacheStale] || self.people == nil) {
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];
    self.peopleRequestOperation = [[FDAPIClient sharedClient] getPeopleListSuccess:^(id result) {
        self.people = result;
        //[FDCache cachePeople:result];
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        NSLog(@"failed to get people! %@", error.description);
    }];
}

-(void)viewWillDisappear:(BOOL)animated {
    self.peopleRequestOperation = nil;
    self.followRequestOperation =nil;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

-(void)showProfile:(id)sender {
    [self.delegate performSegueWithIdentifier:@"ViewProfile" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewProfile"]) {
        if ([sender isKindOfClass:[UIButton class]]){
            UIButton *button = sender;
            FDProfileViewController *vc = segue.destinationViewController;
            if (button.titleLabel.text.length){
                //user doesn't have a FOODIA account, so load info from Facebook if applicable
                [vc initWithUserId:button.titleLabel.text];
            } else {
                //this means the user has a FOODIA account
                [vc initWithUserId:[NSString stringWithFormat:@"%i",button.tag]];
            }
        } else {
            FDUser *thisUser = (FDUser*)sender;
            FDProfileViewController *vc = segue.destinationViewController;
            if (thisUser.fbid){
                //user doesn't have a FOODIA account, so load info from Facebook if applicable
                [vc initWithUserId:thisUser.fbid];
            } else {
                //this means the user has a FOODIA account
                [vc initWithUserId:thisUser.userId];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchDisplayController.isActive && self.searchDisplayController.searchBar.text.length > 0){
        return self.filteredPeople.count;
    } else {
        return self.people.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    FDUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:nil options:nil] lastObject];
    }
    if (self.searchDisplayController.isActive && self.filteredPeople.count){
        FDUser *person = [self.filteredPeople objectAtIndex:indexPath.row];
        if (person.fbid.length) {
            [cell setInviteButton];
            [cell.profileButton.titleLabel setText:[NSString stringWithFormat:@"%@",person.fbid]];
            [cell.profileButton.titleLabel setHidden:YES];
            [cell.actionButton addTarget:self action:@selector(inviteUser:) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setTag:indexPath.row];
        } else {
            [cell.actionButton removeTarget:self action:@selector(inviteUser:) forControlEvents:UIControlEventTouchUpInside];
            [cell.profileButton setTag:[person.userId integerValue]];
            [cell.profileButton.titleLabel setText:@""];
            [cell.profileButton.titleLabel setHidden:NO];
            if ([self.follows containsObject:person.userId]) {
                [cell setUnfollowButton];
            } else {
                [cell setFollowButton];
            }
        }
        [cell.profileButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        [cell configureForUser:person];
        return cell;
    } else {
        FDUser *person = [self.people objectAtIndex:indexPath.row];
        if (person.fbid.length) {
            [cell setInviteButton];
            [cell.profileButton.titleLabel setText:[NSString stringWithFormat:@"%@",person.fbid]];
            [cell.profileButton.titleLabel setHidden:YES];
            [cell.actionButton addTarget:self action:@selector(inviteUser:) forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton setTag:indexPath.row];
        } else {
            [cell.profileButton setTag:[person.userId integerValue]];
            [cell.profileButton.titleLabel setText:@""];
            [cell.profileButton.titleLabel setHidden:NO];
            [cell.actionButton removeTarget:self action:@selector(inviteUser:) forControlEvents:UIControlEventTouchUpInside];
            if ([self.follows containsObject:person.userId]) {
                [cell setUnfollowButton];
            } else {
                [cell setFollowButton];
            }
        }
        [cell.profileButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        [cell configureForUser:person];
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

- (void)inviteUser:(id)sender {
    self.facebookId = @"";
    UIButton *button = (UIButton*)sender;
    if (self.searchDisplayController.isActive){
        FDUser *person = [self.filteredPeople objectAtIndex:button.tag];
        self.facebookId = person.fbid;
    } else {
        FDUser *person = [self.people objectAtIndex:button.tag];
        self.facebookId = person.fbid;

    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        [[[UIActionSheet alloc] initWithTitle:@"Send an invite:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"By Text", @"By Email",@"Through Facebook", nil] showInView:self.view];
    } else {
        [[[UIActionSheet alloc] initWithTitle:@"Send an invite:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"By Text", @"By Email", nil] showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self inviteViaText];
            break;
        case 1:
            [self inviteViaEmail];
            break;
        case 2:
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
                [self inviteViaFacebook];
            } else {
                [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            }
        default:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
    }
}

- (void)inviteViaText {
    //Inviting via text
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        NSString *textBody = @"FOODIA is delicious! And it's free in the app store: itms-apps://itunes.com/apps/foodia";
        viewController.messageComposeDelegate = self;
        [viewController setBody:textBody];
        [self.delegate presentModalViewController:viewController animated:YES];
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

- (void)inviteViaEmail {
        //Inviting via mail
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = @"FOODIA is delicious! Get your eat together and take a look: <a href='http://www.foodia.com'>Download the app now!</a>";
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:@"FOODIA!"];
            if (controller) [self.delegate presentModalViewController:controller animated:YES];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your invitation. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
            [alert show];
        }
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

-(void)inviteViaFacebook{
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (!error) {
                // If permissions granted, publish the story
                if ([FBSession.activeSession.permissions
                     indexOfObject:@"publish_actions"] != NSNotFound) {
                    NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:_facebookId forKey:@"fbid"];
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"SendInvite"
                     object:inviteRecipient];
                    NSLog(@"sending invite from userCell");
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we can't send invites through Facebook without your permission." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            }
        }];
    } else if ([FBSession.activeSession.permissions
                indexOfObject:@"publish_actions"] != NSNotFound) {
        // If permissions present, publish the story
        NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:_facebookId forKey:@"fbid"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"SendInvite"
         object:inviteRecipient];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0){
        [[FDAPIClient sharedClient] getUsersForQuery:searchText success:^(NSArray *result) {
            [personQueryResults removeAllObjects];
            personQueryResults = [result mutableCopy];
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"error from user search: %@",error.description);
        }];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO animated:YES];
    [self.filteredPeople removeAllObjects];
    //[self getFollows];
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isKindOfClass:[FDSocialViewController class]]){
        if (self.searchDisplayController.isActive){
            [self.delegate performSegueWithIdentifier:@"ViewProfile" sender:[self.filteredPeople objectAtIndex:indexPath.row]];
        } else {
            [self.delegate performSegueWithIdentifier:@"ViewProfile" sender:[self.people objectAtIndex:indexPath.row]];
        }
        
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    /*
     Update the filtered array based on the search text and scope.
     */
    
    [self.filteredPeople removeAllObjects]; // First clear the filtered array.
    
    /*
     Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
     */
    if (personQueryResults.count) {
        for (FDUser *person in personQueryResults)
        { 
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:person.name]) {
                [self.filteredPeople addObject:person];
            }
        }
    } else {
        for (FDUser *person in self.people)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:person.name]) {
                [self.filteredPeople addObject:person];
            }
        }
    }
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:nil];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}


@end
