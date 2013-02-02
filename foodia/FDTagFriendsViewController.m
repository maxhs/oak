//
//  FDTagFriendsViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDTagFriendsViewController.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDUserCell.h"

@interface FDTagFriendsViewController ()
@property (nonatomic, retain) NSMutableSet *taggedFriendFacebookIds;
@end

@implementation FDTagFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"foodiaBackground.png"]];
	self.taggedFriendFacebookIds = [NSMutableSet set];
    [FDPost.userPost.withFriends enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.taggedFriendFacebookIds addObject:[obj facebookId]];
    }];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,200,44);
    navTitle.text = @"I'M WITH";
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor whiteColor];
    navTitle.textAlignment = UITextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
    // Shift the title down a bit...
    //[self.navigationController.navigationBar setTitleVerticalPositionAdjustment:0.0f forBarMetrics:UIBarMetricsDefault];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self save];
}

- (void)save {
    FDPost.userPost.withFriends = [[NSSet setWithArray:self.people] objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [self.taggedFriendFacebookIds containsObject:[obj facebookId]];
    }];
}

#pragma mark - UITableViewDelegate/DataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUserCell *cell = (FDUserCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.button.hidden = YES;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.facebookId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.facebookId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUser *friend;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        friend = [self.people objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.facebookId]) {
            [self.taggedFriendFacebookIds removeObject:friend.facebookId];
        } else {
            [self.taggedFriendFacebookIds addObject:friend.facebookId];
        }
        [tableView reloadData];
    } else {
        friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.facebookId]) {
            [self.taggedFriendFacebookIds removeObject:friend.facebookId];
        } else {
            [self.taggedFriendFacebookIds addObject:friend.facebookId];
            [self.searchDisplayController setActive:NO animated:YES];
        }
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
