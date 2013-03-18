//
//  FDPeopleTableViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/11/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPeopleTableViewController.h"
#import "FDAPIClient.h"
//#import "FDCache.h"
#import "Utilities.h"
#import "FDUser.h"
#import "FDProfileViewController.h"
#import "Facebook.h"

@interface FDPeopleTableViewController ()

@end

@implementation FDPeopleTableViewController

@synthesize stillRunning;
@synthesize delegate = delegate_;

- (id)initWithDelegate:(id)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        delegate_ = delegate;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    self.stillRunning = true;
    [super viewDidAppear:animated];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showLoadingOverlay];

    // get the cached people list
    //self.people = [FDCache getCachedPeople];
    //self.filteredPeople = [[FDCache getCachedPeople] mutableCopy];
    //[self.tableView reloadData];
    
    //set custom font in searchBar
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        }
    }
    //replace ugly background
    for (UIView *view in self.searchDisplayController.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
    // if the list is stale, update it
    //if ([FDCache isPeopleCacheStale] || self.people == nil) {
        
        [[FDAPIClient sharedClient] getPeopleListSuccess:^(id result) {
            if(self.stillRunning) {
                self.people = result;
                self.filteredPeople = [self.people mutableCopy];
                //[FDCache cachePeople:result];
                [self.tableView reloadData];
                [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
            }
        } failure:^(NSError *error) {
            NSLog(@"failed to get people! %@", error.description);
        }];
    /*} else {
        [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    }*/
    
}

-(void)viewWillDisappear:(BOOL)animated {
    self.stillRunning = false;
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

-(void)showProfile:(id)sender {
    [self.delegate performSegueWithIdentifier:@"ViewProfile" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewProfile"]) {
        UIButton *button = sender;
        FDProfileViewController *vc = segue.destinationViewController;
        [vc initWithUserId:button.titleLabel.text];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self.filteredPeople count];
    } else {
        // Return the number of rows in the section.
        return self.people.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //self.people = [FDCache getCachedPeople];
    
    static NSString *CellIdentifier = @"UserCell";
    FDUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"FDUserCell" owner:nil options:nil] lastObject];
    }
    cell.button.layer.cornerRadius = 17.0;
    cell.button.layer.shouldRasterize = YES;
    cell.button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [cell.button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    FDUser *person;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) person = [self.filteredPeople objectAtIndex:indexPath.row];
    else person = [self.people objectAtIndex:indexPath.row];
    
    if([person.active isEqualToNumber:[NSNumber numberWithInt:1]]) {
        if([person.following isEqualToNumber:[NSNumber numberWithInt:1]]) [cell setUnfollowButton];
        else [cell setFollowButton];
    } else {
        //temporarily removing the "invited" conditional while I work out what's going on server-side
        /*if([person.invited isEqualToNumber:[NSNumber numberWithInt:1]]) {
            [cell setInvitedButton];
        } else {*/
            [cell setInviteButton];
            [cell.button setTag:indexPath.row];
    }
    
    UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [profileButton setFrame:CGRectMake(9,7,30,30)];
    [profileButton setBackgroundColor:[UIColor clearColor]];
    [profileButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
    profileButton.titleLabel.text = person.facebookId;
    profileButton.titleLabel.hidden = YES;
    [cell addSubview:profileButton];
    cell.nameLabel.text = person.name;
    [cell setFacebookId:person.facebookId];
    
    return cell;
    
}
/*-(void)setUnfollowed:(id) sender {
    FDUser *newPerson;
    if([self.searchDisplayController.searchBar.text length] != 0) {
        newPerson = [self.filteredPeople objectAtIndex:((UIButton *)sender).tag];
        newPerson.following = [NSNumber numberWithInt:0];
        [self.filteredPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        newPerson = [self.people objectAtIndex:((UIButton *)sender).tag];
        newPerson.following = [NSNumber numberWithInt:0];
        NSMutableArray *newPeople = [self.people mutableCopy];
        [newPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        self.people = [NSArray arrayWithArray:newPeople];
        [self.tableView reloadData];
    }
}
-(void)setFollowed:(id) sender {
    FDUser *newPerson;
    if([self.searchDisplayController.searchBar.text length] != 0) {
        newPerson = [self.filteredPeople objectAtIndex:((UIButton *)sender).tag];
        newPerson.following = [NSNumber numberWithInt:1];
        [self.filteredPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        newPerson = [self.people objectAtIndex:((UIButton *)sender).tag];
        newPerson.following = [NSNumber numberWithInt:1];
        NSMutableArray *newPeople = [self.people mutableCopy];
        [newPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        self.people = [NSArray arrayWithArray:newPeople];
        [self.tableView reloadData];
    }
}
-(void)setInvited:(id) sender {
    FDUser *newPerson;
    if([self.searchDisplayController.searchBar.text length] != 0) {
        newPerson = [self.filteredPeople objectAtIndex:((UIButton *)sender).tag];
        newPerson.invited = [NSNumber numberWithInt:1];
        [self.filteredPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        newPerson = [self.people objectAtIndex:((UIButton *)sender).tag];
        newPerson.invited = [NSNumber numberWithInt:1];
        NSMutableArray *newPeople = [self.people mutableCopy];
        [newPeople replaceObjectAtIndex:((UIButton *)sender).tag withObject:newPerson];
        self.people = [NSArray arrayWithArray:newPeople];
        [self.tableView reloadData];
    }
}*/

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
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
    for (FDUser *person in self.people)
    {
        //if (result == NSOrderedSame)
        //{
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
            if([predicate evaluateWithObject:person.name]) {
                [self.filteredPeople addObject:person];
            }
        //}
    }
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end
