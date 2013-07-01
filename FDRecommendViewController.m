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

@interface FDRecommendViewController () <FBDialogDelegate, UIAlertViewDelegate, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
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
        [self.rightBarButton setTitle:@"SEND"];
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
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
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
            [postParams setObject:@"Inspired by food." forKey:@"name"];
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
                    NSLog(@"does the recommendee have a facebook id?: %@",recommendee.facebookId);
                    [postParams addEntriesFromDictionary:@{@"to":recommendee.facebookId}];
                    [self.facebook dialog:@"feed" andParams:postParams andDelegate:self];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"But we don't have %@'s facebook information. Try sending them a recommendation through FOODIA instead!", recommendee.name] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            }
            /*[[FDAPIClient sharedClient] recommendPost:self.post onFacebook:YES toRecommendees:self.recommendees withMessage:self.post.caption success:^(id result) {
                NSLog(@"success recommending to FOODIA api");
            } failure:^(NSError *error) {
                NSLog(@"error recommending to FOODIA api: %@",error.description);
            }];*/
        }
    } else {
        //NSMutableSet *nonMembers = [NSMutableSet set];
        /*for (FDUser *recommendee in self.recommendees) {
            [[FDAPIClient sharedClient] checkIfUser:recommendee.facebookId success:^(id result) {
                if (![result boolValue]){
                    [self.recommendees removeObject:recommendee];
                    [nonMembers addObject:recommendee];
                }
            } failure:^(NSError *error) {}];
        }
        NSLog(@"new recommendees list: %@",self.recommendees);
        NSLog(@"non member set: %@", nonMembers);
        if (nonMembers.count != 0) [[[UIAlertView alloc] initWithTitle:@"Uh-oh!" message:@"Looks like one or more of your friends isn't on FOODIA. You should send them an invite to join!" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Send Invite",nil] show];*/
        NSLog(@"self.recommendees: %@",self.recommendees);
        [[FDAPIClient sharedClient] recommendPost:self.post onFacebook:NO toRecommendees:self.recommendees withMessage:self.post.caption success:^(id result) {
            NSLog(@"success recommending to FOODIA api: %@",result);
            [[[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"Isn't it fun helping your friends find great food?" delegate:self cancelButtonTitle:@"Yup!" otherButtonTitles:nil] show];
        } failure:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your recommendation right now." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            NSLog(@"error recommending to FOODIA api: %@",error.description);
        }];
    }
    [self.recommendees removeAllObjects];
    [self.recommendeeList removeAllObjects];
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
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Send Invite"]){
        [[[UIActionSheet alloc] initWithTitle:@"Send an invite to join FOODIA!" delegate:self cancelButtonTitle:@"No Thanks" destructiveButtonTitle:nil otherButtonTitles:@"Send via Text", @"Send via Email", nil] showInView:self.view];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yup!"]){
        [self.navigationController popViewControllerAnimated:YES];
    }
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex == 0) {
        //Recommending via text
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]){
            NSString *textBody = @"I think you should join FOODIA!";
            viewController.messageComposeDelegate = self;
            [viewController setBody:textBody];
            [self.delegate presentModalViewController:viewController animated:YES];
        }
    } else if(buttonIndex == 1) {
        //Recommending via mail
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSString *emailBody = [NSString stringWithFormat:@"Download FOODIA! <a href='http://itunes.com/apps/foodia'>download the app now!</a>"];
            [controller setMessageBody:emailBody isHTML:YES];
            [controller setSubject:@"Download FOODIA!"];
            if (controller) [self.delegate presentModalViewController:controller animated:YES];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to email your invite. Please try again..." delegate:self cancelButtonTitle:@"" otherButtonTitles:nil];
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

@end
