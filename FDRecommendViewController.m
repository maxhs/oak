//
//  FDRecommendViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecommendViewController.h"
#import "FDAPIClient.h"
#import "FDUser.h"
#import "FDShareRecViewController.h"
#import "FDUserCell.h"

@interface FDRecommendViewController ()
@property (nonatomic, retain) NSMutableSet *recommendees;
@property (nonatomic, retain) NSMutableArray *recommendeeList;
@end

@implementation FDRecommendViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.recommendees = [NSMutableSet set];
    self.recommendeeList = [NSMutableArray array];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,320,44);
    navTitle.text = @"RECOMMENDING";
    
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = UITextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
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
    self.searchDisplayController.searchBar.placeholder = @"Search for your friend(s)";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)recommend:(id)sender {
    FDShareRecViewController *shareRecViewController = [[FDShareRecViewController alloc] initWithNibName:@"FDShareRecViewController"
                                                                                         bundle:nil];
    [shareRecViewController setRecipients:self.recommendees];
    [shareRecViewController setPost:self.post];
    [self presentViewController:shareRecViewController
                       animated:YES
                     completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDUserCell *cell = (FDUserCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.button.hidden = YES;
    if(self.searchDisplayController.searchBar.text.length == 0) {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
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
        if ([self.recommendees containsObject:friend]) {
            [self.recommendees removeObject:friend];
        } else {
            [self.recommendees addObject:friend];
            [self.recommendeeList addObject:friend];
        }
        [tableView reloadData];
    } else {
        friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
            [self.recommendees removeObject:friend];
        } else {
            [self.recommendees addObject:friend];
            [self.recommendeeList addObject:friend];
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
