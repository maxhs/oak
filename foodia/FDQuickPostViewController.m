//
//  FDQuickPostViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 6/9/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDQuickPostViewController.h"
#import "FDPost.h"
#import <CoreLocation/CoreLocation.h>
#import "FDVenue.h"
#import "FDFoodiaTag.h"
#import <QuartzCore/QuartzCore.h>
#import "FDAPIClient.h"
#import "FDAppDelegate.h"

@interface FDQuickPostViewController () {
    CLLocationManager *locationManager;
    NSArray *venues;
    NSMutableArray *allTags;
    UIScrollView *tagScrollView;
    int previousTagOriginX;
    int previousTagButtonSize;
    int tagScrollViewContentSize;
    UITextField *foodObjectTextField;
    UIButton *locationButton;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *postBarButton;
-(IBAction)post;
@end

@implementation FDQuickPostViewController

@synthesize categoryPhrase;

- (void)viewDidLoad
{
    
    locationManager = [CLLocationManager new];
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    locationManager.delegate = self;
    
    venues = [NSArray array];
    allTags = [NSMutableArray array];
    [locationManager startUpdatingLocation];
    //[super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.navigationController isNavigationBarHidden]){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self updateVenuesForLocation:locations.lastObject];
    FDPost.userPost.location = locations.lastObject;
    [manager stopUpdatingLocation];
}

- (void)updateVenuesForLocation:(CLLocation *)location {
    // if the cached venues are from the same location, just use them
    CLLocation *lastLocation = [[FDFoursquareAPIClient sharedClient] lastLocation];
    CGFloat comparisonThreshold = 0.001;
    
    if (fabsf(location.coordinate.latitude - lastLocation.coordinate.latitude) < comparisonThreshold
        && fabsf(location.coordinate.longitude - lastLocation.coordinate.longitude) < comparisonThreshold) {
        venues = [[FDFoursquareAPIClient sharedClient] venues];
        [self.tableView reloadData];
    } else {
        // otherwise, request new ones
        [[FDFoursquareAPIClient sharedClient] getVenuesNearLocation:location success:^(NSArray *results) {
            venues = results;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't connect to Foursquare!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"QuickPostCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0:
        {
            if (!locationButton) {
                locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [locationButton setFrame:cell.frame];
                [locationButton addTarget:self action:@selector(goToAddLocation) forControlEvents:UIControlEventTouchUpInside];
                [cell addSubview:locationButton];
                [locationButton setFrame:CGRectMake(cell.frame.size.width-254, (cell.frame.size.height/2)-22, 242, 44)];
                [locationButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
                [locationButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [locationButton setAlpha:0.0];
            }
            [cell.textLabel setText:@"I'm at:"];
            if (FDPost.userPost.locationName.length){
                [locationButton setTitle:[NSString stringWithFormat:@"%@",FDPost.userPost.locationName] forState:UIControlStateNormal];
                [locationButton setBackgroundImage:[UIImage imageNamed:@"locationBubble"] forState:UIControlStateNormal];
                [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    [locationButton setAlpha:1.0];
                }completion:^(BOOL finished) {}];
            } else {
                if (venues.count){
                    [locationButton setTitle:[NSString stringWithFormat:@"%@",[(FDVenue*)[venues objectAtIndex:0] name]] forState:UIControlStateNormal];
                    [locationButton setBackgroundImage:[UIImage imageNamed:@"locationBubble"] forState:UIControlStateNormal];
                    [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        [locationButton setAlpha:1.0];
                    }completion:^(BOOL finished) {}];
                } else {
                    cell.textLabel.text = @"";
                }
            }
            
            
        }
            break;
        case 1:
            
            if (!foodObjectTextField){
                foodObjectTextField = [[UITextField alloc] init];
                foodObjectTextField.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
                [foodObjectTextField setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
                [foodObjectTextField setDelegate:self];
                [foodObjectTextField setReturnKeyType:UIReturnKeyDone];
                [foodObjectTextField setTextColor:[UIColor darkGrayColor]];
                [foodObjectTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            }
            if (FDPost.userPost.foodiaObject.length) {
                NSString *categoryString = [FDPost.userPost.category lowercaseString];
                if ([FDPost.userPost.category isEqualToString:kShopping]) categoryString = [categoryString stringByAppendingString:@" for"];
                [cell.textLabel setText:[NSString stringWithFormat:@"I'm %@ %@", categoryString, FDPost.userPost.foodiaObject]];
            } else {
                [foodObjectTextField setPlaceholder:self.categoryPhrase];
                [cell.textLabel setHidden:YES];
                [cell addSubview:foodObjectTextField];
                [foodObjectTextField setFrame:CGRectMake(20, 0, cell.frame.size.width-40, cell.frame.size.height)];
            }
            break;
        case 2:
            if (FDPost.userPost.tagArray.count == 0){
                [cell.textLabel setText:@"Do you want to add tags?"];
                UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [tagButton setFrame:cell.frame];
                [tagButton addTarget:self action:@selector(goToTagController) forControlEvents:UIControlEventTouchUpInside];
                [cell addSubview:tagButton];
            } else {
                [cell.textLabel setHidden:YES];
                if (!tagScrollView){
                    tagScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 10, cell.frame.size.width-20, cell.frame.size.height-20)];
                    tagScrollView.delegate = self;
                    [cell addSubview:tagScrollView];
                }
                [self loadTagArray];
            }
            break;
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([UIScreen mainScreen].bounds.size.height == 568){
        return 66;
    } else {
        return 50;
    }
}

- (void)goToAddLocation {
    [self performSegueWithIdentifier:@"AddLocation" sender:self];
}

- (void)goToTagController {
    [self performSegueWithIdentifier:@"AddTags" sender:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)loadTagArray{
    if (FDPost.userPost.tagArray.count){
        allTags = FDPost.userPost.tagArray;
        previousTagOriginX = 3;
        previousTagButtonSize = 0;
        tagScrollViewContentSize = 0;
        [tagScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (FDFoodiaTag *tag in allTags){
            UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [tagButton addTarget:self action:@selector(goToTagController) forControlEvents:UIControlEventTouchUpInside];
            [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
            [tagButton setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
            tagButton.layer.shadowColor = [UIColor lightGrayColor].CGColor;
            tagButton.layer.shadowRadius = 3.f;
            tagButton.layer.shadowOffset = CGSizeMake(0,0);
            tagButton.layer.shadowOpacity = .2f;
            tagButton.layer.borderColor = [UIColor colorWithWhite:.90 alpha:1].CGColor;
            tagButton.layer.borderWidth = 1.0f;
            tagButton.layer.cornerRadius = 17.0f;
            [tagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            CGSize stringSize = [tagButton.titleLabel.text sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
            [tagButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
            [tagButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [tagButton setFrame:CGRectMake(previousTagOriginX+previousTagButtonSize,4,stringSize.width+20,34)];
            previousTagButtonSize = tagButton.frame.size.width + 5;
            tagScrollViewContentSize += previousTagButtonSize;
            previousTagOriginX = tagButton.frame.origin.x;
            [tagScrollView addSubview:tagButton];
        }
        [tagScrollView setContentSize:CGSizeMake(tagScrollViewContentSize,42)];
    }
}

- (IBAction)post{
    [FDPost.userPost setFoodiaObject:foodObjectTextField.text];
    [[FDAPIClient sharedClient] quickPost:FDPost.userPost success:^(id result) {

    } failure:^(NSError *error) {
        NSLog(@"Error quick posting: %@",error.description);
    }];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (foodObjectTextField.text.length) [FDPost.userPost setFoodiaObject:foodObjectTextField.text];
    [super viewDidDisappear:animated];
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

@end
