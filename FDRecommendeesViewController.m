//
//  FDRecommendeesViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/27/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecommendeesViewController.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDUserCell.h"

@interface FDRecommendeesViewController ()
@property (nonatomic, retain) NSMutableSet *recommendeeIds;
@end

@implementation FDRecommendeesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.recommendeeIds = [NSMutableSet set];
    [FDPost.userPost.recommendedTo enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.recommendeeIds addObject:[obj facebookId]];
    }];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,200,44);
    //RESET FRAME TO ACCOMODATE LEFT BUT NO RIGHT BAR BUTTON
    navTitle.text = @"I'M RECOMMENDING TO";
    
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
    FDPost.userPost.recommendedTo = [[NSSet setWithArray:self.people] objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [self.recommendeeIds containsObject:[obj facebookId]];
    }];
}

#pragma mark - UITableViewDelegate/DataSource Methods




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUserCell *cell = (FDUserCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.button.hidden = YES;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        if ([self.recommendeeIds containsObject:friend.facebookId]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendeeIds containsObject:friend.facebookId]) {
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
        if ([self.recommendeeIds containsObject:friend.facebookId]) {
            [self.recommendeeIds removeObject:friend.facebookId];
        } else {
            [self.recommendeeIds addObject:friend.facebookId];
        }
        [tableView reloadData];
    } else {
        friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendeeIds containsObject:friend.facebookId]) {
            [self.recommendeeIds removeObject:friend.facebookId];
        } else {
            [self.recommendeeIds addObject:friend.facebookId];
            NSLog(@"friend recommended!");
            [self.searchDisplayController setActive:NO animated:YES];
        }
        [self.searchDisplayController.searchResultsTableView reloadData];
        [tableView reloadData];
    }
    return indexPath;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
