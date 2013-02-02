//
//  FDSocialViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDSocialViewController.h"
#import "ECSlidingViewController.h"
#import "FDUser.h"
#import "FDUserCell.h"
#import "FDProfileViewController.h"
#import "FDModalNoAnimationSegue.h"
#import "FDAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "FDShareViewController.h"

@interface FDSocialViewController ()
@property (nonatomic, retain) NSMutableArray *friends;

- (IBAction)revealMenu:(UIBarButtonItem *)sender;

@end

@implementation FDSocialViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
      self.navigationItem.title = @"FRIENDS & INVITES";
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TestFlight passCheckpoint:@"Passed Social View checkpoint"];
    self.delegate = self;
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,190,44);
    navTitle.text = @"FRIENDS & INVITES";
    navTitle.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = UITextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
    // Shift the title down a bit...
    //[self.navigationController.navigationBar setTitleVerticalPositionAdjustment:-1 forBarMetrics:UIBarMetricsDefault];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendInvite:) name:@"SendInvite" object:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    for (UIView *view in self.searchDisplayController.searchBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
            [view addSubview:header];
            break;
        }
    }
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate showFacebookWallPost];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate removeFacebookWallPost];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) sendInvite:(NSNotification *)notification {
    NSString *recipient = [notification.object objectForKey:@"fbid"];
    NSLog(@"recipient: %@", recipient);
    
    /*BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:vc initialText:@"Download FOODIA. Spend less time with your phone and more time with your food." image:[UIImage imageNamed:@"FOODIA_crab_114x114.png"] url:[NSURL URLWithString:@"http://www.foodia.com"] handler:^(FBNativeDialogResult result, NSError *error) {

        // Only show the error if it is not due to the dialog
        // not being supporte, i.e. code = 7, otherwise ignore
        // because our fallback will show the share view controller.
        if (error && [error code] == 7) {
            return;
            NSLog(@"there was an error code7");
        }
        NSString *alertText = @"";
        if (error) {
            alertText = [NSString stringWithFormat:
                         @"error: domain = %@, code = %d",
                         error.domain, error.code];
        } else if (result == FBNativeDialogResultSucceeded) {
            alertText = @"Good going telling a friend about FOODIA! Why not tell another?";
        }
        if (![alertText isEqualToString:@""]) {
            // Show the result in an alert
            [[[UIAlertView alloc] initWithTitle:@"Thanks!"
                                        message:alertText
                                       delegate:self
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil]
             show];
        }
    }];*/
    
    //if (!displayedNativeDialog) {
        FDShareViewController *viewController =
        [[FDShareViewController alloc] initWithNibName:@"FDShareViewController"
                                              bundle:nil];
        viewController.recipient = recipient;
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    //}
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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

/*- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];

    return cell;
}*/

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView reloadData];
    return indexPath;
}

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate removeFacebookWallPost];
}

@end
