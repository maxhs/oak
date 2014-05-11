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
@property (nonatomic, retain) NSMutableSet *taggedFriendIds;
@end

@implementation FDTagFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.taggedFriendFacebookIds = [NSMutableSet set];
    self.taggedFriendIds = [NSMutableSet set];
    [FDPost.userPost.withFriends enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj userId]){
            [self.taggedFriendIds addObject:[obj userId]];
        } else {
            [self.taggedFriendFacebookIds addObject:[obj fbid]];
        }
    }];
    
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,180,44);
    navTitle.text = @"I'm with";
    navTitle.font = [UIFont fontWithName:kHelveticaNeueThin size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;

    //set custom font in searchBar
    for(UIView *subView in self.searchDisplayController.searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kHelveticaNeueThin size:15];
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
        return ([self.taggedFriendIds containsObject:[obj userId]] || [self.taggedFriendFacebookIds containsObject:[obj fbid]]);
    }];
}

#pragma mark - UITableViewDelegate/DataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUserCell *cell = (FDUserCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    UIView *cellbg = [[UIView alloc] init];
    [cellbg setBackgroundColor:[UIColor darkGrayColor]];
    cell.selectedBackgroundView = cellbg;
    cell.actionButton.hidden = YES;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.fbid]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else if ([self.taggedFriendIds containsObject:friend.userId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.fbid]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else if ([self.taggedFriendIds containsObject:friend.userId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUser *friend;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        friend = [self.people objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.fbid]) {
            [self.taggedFriendFacebookIds removeObject:friend.fbid];
        } else if ([self.taggedFriendIds containsObject:friend.userId]) {
            [self.taggedFriendIds removeObject:friend.userId];
        } else {
            if (friend.userId.length) {
                [self.taggedFriendIds addObject:friend.userId];
            } else {
                [self.taggedFriendFacebookIds addObject:friend.fbid];
            }
        }
    } else {
        friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.taggedFriendFacebookIds containsObject:friend.fbid]) {
            [self.taggedFriendFacebookIds removeObject:friend.fbid];
        } else if ([self.taggedFriendIds containsObject:friend.userId]) {
            [self.taggedFriendIds removeObject:friend.userId];
        } else {
            if (friend.userId.length) {
                [self.taggedFriendIds addObject:friend.userId];
            } else {
                [self.taggedFriendFacebookIds addObject:friend.fbid];
            }
        }
    }
    [self.filteredPeople removeAllObjects];
    [self.searchDisplayController setActive:NO animated:YES];
    [tableView reloadData];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
