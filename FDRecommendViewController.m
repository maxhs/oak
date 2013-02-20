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
#import "FDUserCell.h"
#import "FDPost.h"

@interface FDRecommendViewController () <FBDialogDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) NSMutableSet *recommendees;
@property (nonatomic, retain) NSMutableArray *recommendeeList;
@property (strong, nonatomic) Facebook *facebook;
@end

@implementation FDRecommendViewController
@synthesize facebook = _facebook;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.recommendees = [NSMutableSet set];
    self.recommendeeList = [NSMutableArray array];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,320,44);
    navTitle.text = @"RECOMMENDING";
    
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
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

#pragma Facebook stuff
- (IBAction)recommend:(id)sender {
    NSMutableDictionary *postParams = [[NSMutableDictionary alloc] init];
    if (FBSession.activeSession.isOpen) {
        // Initiate a Facebook instance and properties
        if (nil == self.facebook) {
            self.facebook = [[Facebook alloc]
                             initWithAppId:FBSession.activeSession.appID
                             andDelegate:nil];
            NSLog(@"initializing and storing a facebook session/object");
            
            // Store the Facebook session information
            self.facebook.accessToken = FBSession.activeSession.accessToken;
            self.facebook.expirationDate = FBSession.activeSession.expirationDate;
        }
    } else {
        NSLog(@"you're not signed in to facebook, so you can't share");
        // Clear out the Facebook instance
        self.facebook = nil;
    }

    if (self.post.foodiaObject != nil) {
        [postParams setObject:self.post.foodiaObject forKey:@"name"];
    } else {
        [postParams setObject:@"Download FOODIA!" forKey:@"name"];
    }

    if (self.post.identifier) {
        [postParams setObject:[NSString stringWithFormat:@"http://posts.foodia.com/p/%@",self.post.identifier] forKey:@"link"];
    } else {
        [postParams setObject:@"http://posts.foodia.com/" forKey:@"link"];
    }

    if (self.post.hasPhoto){
        NSString *detailString = [self.post.feedImageUrlString stringByReplacingOccurrencesOfString:@"thumb" withString:@"original"];
        [postParams setObject:detailString forKey:@"picture"];
    } else {
        [postParams setObject:@"http://foodia.com/images/FOODIA_red_512x512_bg.png" forKey:@"picture"];
    }
    
    if (self.recommendees != nil) {
        for (FDUser *recommendee in self.recommendees){
            [postParams addEntriesFromDictionary:@{@"to":recommendee.facebookId}];
            NSLog(@"new postParams: %@",postParams);
            [self.facebook dialog:@"feed" andParams:postParams andDelegate:self];
        }
        [[FDAPIClient sharedClient] recommendPost:self.post toRecommendees:self.recommendees withMessage:self.post.caption success:^(id result) {
            NSLog(@"success recommending to FOODIA api: %@",result);
        } failure:^(NSError *error) {
            NSLog(@"error recommending to FOODIA api: %@",error.description);
        }];
    }
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    NSLog(@"error: %@", error.description);
}

/*- (void)dialogDidNotComplete:(FBDialog *)dialog {
    NSLog(@"Dialog did NOT complete: %@", dialog);
    [dialog dismissWithSuccess:YES animated:YES];
}*/

// Handle the publish feed call back
- (void)dialogCompleteWithUrl:(NSURL *)url {
    NSDictionary *params = [self parseURLParams:[url query]];
    NSLog(@"params: %@", params);
    if ([params count] != 0) [[[UIAlertView alloc] initWithTitle:@"Good Going!"
                                message:@"Recommendations make the world turn. Why not make another?"
                               delegate:self
                      cancelButtonTitle:@"Okay"
                      otherButtonTitles:nil]
     show];
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}


@end
