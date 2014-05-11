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
#import <MessageUI/MessageUI.h>

@interface FDRecommendViewController () <FBDialogDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
@property (nonatomic, retain) NSMutableSet *recommendees;
@property (nonatomic, retain) NSMutableArray *recommendeeList;
@property (strong, nonatomic) Facebook *facebook;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@end

@implementation FDRecommendViewController
@synthesize facebook = _facebook;
@synthesize postingToFacebook = _postingToFacebook;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.postingToFacebook){
        [self.rightBarButton setTitle:@"Send"];
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.recommendees = [NSMutableSet set];
    self.recommendeeList = [NSMutableArray array];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(80,0,160,44);
    navTitle.text = @"Recommending";
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
    cell.actionButton.hidden = YES;
    if (self.searchDisplayController.isActive && self.filteredPeople.count) {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            NSLog(@"show a checkmark filtered");
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        [cell configureForUser:friend];
        if ([self.recommendees containsObject:friend]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            NSLog(@"show a checkmark");
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.searchDisplayController.isActive && self.filteredPeople.count) {
        FDUser *friend = [self.filteredPeople objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
            [self.recommendees removeObject:friend];
        } else {
            [self.recommendees addObject:friend];
            [self.recommendeeList addObject:friend];
        }
        [self.filteredPeople removeAllObjects];
        [self.searchDisplayController setActive:NO animated:YES];
    } else {
        FDUser *friend = [self.people objectAtIndex:indexPath.row];
        if ([self.recommendees containsObject:friend]) {
            [self.recommendees removeObject:friend];
        } else {
            [self.recommendees addObject:friend];
            [self.recommendeeList addObject:friend];
        }
    }
    [self.tableView reloadData];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma Facebook stuff
- (IBAction)recommend:(id)sender {
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
    if (self.recommendees.count){
        if (self.postingToFacebook){
            NSMutableDictionary *postParams = [[NSMutableDictionary alloc] init];
            if (FBSession.activeSession.isOpen) {
                // Initiate a Facebook instance and properties
                if (nil == self.facebook) {
                    self.facebook = [[Facebook alloc]
                                     initWithAppId:FBSession.activeSession.appID
                                     andDelegate:nil];
                    
                    // Store the Facebook session information
                    self.facebook.accessToken = FBSession.activeSession.accessToken;
                    self.facebook.expirationDate = FBSession.activeSession.expirationDate;
                }
            } else {
                // Clear out the Facebook instance
                self.facebook = nil;
            }

            if (self.post.foodiaObject != nil) {
                [postParams setObject:self.post.foodiaObject forKey:@"name"];
            } else {
                [postParams setObject:@"Inspired by this food." forKey:@"name"];
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
                [postParams setObject:@"http://foodia.com/images/logo.png" forKey:@"picture"];
            }
            
            if (self.recommendees != nil) {
                for (FDUser *recommendee in self.recommendees){
                    if (recommendee.facebookId.length){
                        //NSLog(@"does the recommendee have a facebook id?: %@",recommendee.facebookId);
                        [postParams addEntriesFromDictionary:@{@"to":recommendee.facebookId}];
                        [self.facebook dialog:@"feed" andParams:postParams andDelegate:self];
                        [[FDAPIClient sharedClient] recommendPostOnFacebook:self.post success:^(id result) {} failure:^(NSError *error) {}];
                    } else if (recommendee.fbid.length) {
                        //NSLog(@"does the recommendee have an fbid?: %@",recommendee.fbid);
                        [postParams addEntriesFromDictionary:@{@"to":recommendee.fbid}];
                        [self.facebook dialog:@"feed" andParams:postParams andDelegate:self];
                        [[FDAPIClient sharedClient] recommendPostOnFacebook:self.post success:^(id result) {} failure:^(NSError *error) {}];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"But we don't have %@'s facebook information. Try sending them a recommendation through FOODIA instead!", recommendee.name] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
                }
            }
            [self.recommendees removeAllObjects];
            [self.recommendeeList removeAllObjects];
        } else {
            [[FDAPIClient sharedClient] recommendPost:self.post onFacebook:NO toRecommendees:self.recommendees withMessage:self.post.caption success:^(id result) {
                [[[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"Isn't it fun helping your friends find great food?" delegate:self cancelButtonTitle:@"Yup!" otherButtonTitles:nil] show];
                [self.recommendees removeAllObjects];
                [self.recommendeeList removeAllObjects];
            } failure:^(NSError *error) {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Your recipient(s) may not have FOODIA yet. You should tell them to join already!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                NSLog(@"Error recommending through FOODIA api: %@",error.description);
                [self.recommendees removeAllObjects];
                [self.recommendeeList removeAllObjects];
            }];
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Uh-oh!" message:@"You didn't say who you wanted to recommend to. Give it another shot." delegate:self cancelButtonTitle:@"Will do" otherButtonTitles:nil] show];
    }
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    NSLog(@"Error with FB Dialog: %@", error.description);
}

/*- (void)dialogDidNotComplete:(FBDialog *)dialog {
    NSLog(@"Dialog did NOT complete: %@", dialog);
    [dialog dismissWithSuccess:YES animated:YES];
}*/

// Handle the publish feed call back
- (void)dialogCompleteWithUrl:(NSURL *)url {
    NSDictionary *params = [self parseURLParams:[url query]];
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
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yup!"]) {
        NSDictionary *userInfo = @{@"post":self.post,@"identifier":self.post.identifier};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RowToReloadFromMenu" object:nil userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePostNotification" object:nil userInfo:userInfo];
        [self.navigationController popViewControllerAnimated:YES];
    }
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

@end
