//
//  FDFoodViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "Flurry.h"
#import "FDFoodViewController.h"
#import "FDPost.h"
#import "FDPostViewController.h"
#import "FDFoodiaTag.h"
#import "FDPostsTagsViewController.h"
#import "FDCategoryPostsViewController.h"

@interface FDFoodViewController () {
    BOOL iPhone5;
    int previousOriginX;
    int previousOriginY;
    int previousButtonSize;
    UIButton *tagButtonToRemove;
    int rowIndex;
    int homeCount;
    NSMutableDictionary *categoryCountDict;
    NSMutableArray *posts;
    NSMutableArray *tagsForTimePeriod;
    FDFoodiaTag *maxTag;
    int maxTagCount;
    FDFoodiaTag *secondTag;
    int secondTagCount;
    int trackedTagCount;
    NSMutableArray *tagsForTagNames;
    NSMutableArray *tagsForTracking;
    NSMutableArray *filteredTagsForTagNames;
    int totalRowNumber;
    FDFoodiaTag *tagToTrack;
    FDFoodiaTag *tagForRemoval;
}

@property (weak, nonatomic) IBOutlet UIButton *weekButton;
@property (weak, nonatomic) IBOutlet UIButton *monthButton;
@property (weak, nonatomic) IBOutlet UIButton *yearButton;
@property (weak, nonatomic) IBOutlet UIView *tagContainerView;
-(IBAction)week;
-(IBAction)month;
-(IBAction)year;
-(IBAction)rightBarButtonAction;
@end

@implementation FDFoodViewController

@synthesize categoryName = _categoryName, timePeriod = _timePeriod;

- (void)viewDidLoad
{
    [super viewDidLoad];
    categoryCountDict = [NSMutableDictionary dictionary];
    if (!posts) posts = [NSMutableArray array];
    if (!tagsForTimePeriod) tagsForTimePeriod = [NSMutableArray array];
    if (!tagsForTagNames) tagsForTagNames = [NSMutableArray array];
    if (!tagsForTracking) tagsForTracking = [NSMutableArray array];
    if (!filteredTagsForTagNames) filteredTagsForTagNames = [NSMutableArray array];
	
    [Flurry logEvent:@"Viewing My Digest" timed:YES];
    
    if ([UIScreen mainScreen].bounds.size.height == 568) iPhone5 = YES;
    else iPhone5 = NO;
    self.tableView.tableHeaderView = self.mapContainerView;
    [self resetMapForTimePeriod:kWeek];
    [self getCategoryCountsForTimePeriod:kWeek];

    _timePeriod = kWeek;
    [self selectTimeButton:self.weekButton];
    rowIndex = 1;
    [self getTags];
}

- (IBAction)rightBarButtonAction {
    
    if (self.mapView.frame.origin.y == 0){
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [self.tableView setContentOffset:CGPointZero animated:YES];
            [self.mapView setFrame:CGRectMake(0, 44, 320, 146)];
            [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"up_arrow"]];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.tableView setContentOffset:CGPointZero animated:YES];
            self.mapView.transform = CGAffineTransformIdentity;
            [self.mapView setFrame:CGRectMake(0, 0, 320, 190)];
            [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"down_arrow"]];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)getCategoryCountsForTimePeriod:(NSString*)timePeriod {
    [[FDAPIClient sharedClient] getCategoryCountsForTime:timePeriod success:^(id result) {
        categoryCountDict = result;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"Error from category count method: %@",error.description);
    }];
}

- (IBAction)week {
    [self resetButtonColors];
    [self selectTimeButton:self.weekButton];
    [self resetMapForTimePeriod:kWeek];
    [self getCategoryCountsForTimePeriod:kWeek];
    _timePeriod = kWeek;
}

- (IBAction)month {
    [self resetButtonColors];
    [self selectTimeButton:self.monthButton];
    [self resetMapForTimePeriod:kMonth];
    [self getCategoryCountsForTimePeriod:kMonth];
    _timePeriod = kMonth;
}

- (IBAction)year {
    [self resetButtonColors];
    [self selectTimeButton:self.yearButton];
    [self resetMapForTimePeriod:kYear];
    [self getCategoryCountsForTimePeriod:kYear];
    _timePeriod = kYear;
}

- (void)resetButtonColors{
    [self deselectTimeButton:self.weekButton];
    [self deselectTimeButton:self.monthButton];
    [self deselectTimeButton:self.yearButton];
}

- (void)selectTimeButton:(UIButton*)button{
    [button setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)deselectTimeButton:(UIButton*)button{
    [button setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
}

- (void)resetMapForTimePeriod:(NSString*)timePeriod {
    [posts removeAllObjects];
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate showLoadingOverlay];
    [[FDAPIClient sharedClient] getPostsFromTimePeriod:timePeriod success:^(id result) {
        posts = result;
        [self showPostsOnMap];
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } failure:^(NSError *error) {
        //NSLog(@"Failure from time period method: %@",error.description);
    }];
    [self getTagsForTimePeriod:timePeriod];
}

- (void)getTags {
    [[FDAPIClient sharedClient] getTagsForUserSuccess:^(id result) {
        tagsForTagNames = [result mutableCopy];
    } failure:^(NSError *error) {
        
    }];
}

- (void)getTagsForTimePeriod:(NSString*)timePeriod{
    [[FDAPIClient sharedClient] getTagsForTimePeriod:timePeriod success:^(id result) {
        tagsForTimePeriod = result;
        [self refreshTags];
        [[FDAPIClient sharedClient] getTrackedTagsForTimePeriod:timePeriod success:^(id result) {
            tagsForTracking = [result mutableCopy];
            totalRowNumber = 4 + tagsForTracking.count;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to fetch your tags. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    } failure:^(NSError *error) {
        NSLog(@"error from getTagsForTimePeriods method: %@",error.description);
    }];
}

- (void)refreshTags {
    //reset the elements each time
    previousOriginX = 44;
    previousButtonSize = 0;
    previousOriginY = 0;
    maxTagCount = 0;
    maxTag = nil;
    
    [self.tagContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIImageView *tagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag"]];
    [self.tagContainerView addSubview:tagImageView];
    [tagImageView setFrame:CGRectMake(6, 4, 26, 26)];
    if (tagsForTimePeriod.count){
        CGFloat rowHeight = 34;
        for (FDFoodiaTag *tag in tagsForTimePeriod){
            //reset alpha to baseline for each tag
            CGFloat alpha = 0.5f;
            
            //get info for the tag label
            if ([tag.postsCount intValue] >= maxTagCount) {
                if (maxTag) {
                    secondTag = maxTag;
                    secondTagCount = maxTagCount;
                }
                maxTag = tag;
                maxTagCount = [tag.postsCount intValue];
            } else if ([tag.postsCount intValue] >= secondTagCount){
                secondTag = tag;
                secondTagCount = [tag.postsCount intValue];
            }
            
            UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
            alpha += (.1 * [tag.postsCount floatValue]);
            [tagButton setBackgroundColor:[self setTagColor:tag.color andAlpha:alpha]];
            [tagButton addTarget:self action:@selector(showPostsForTag:) forControlEvents:UIControlEventTouchUpInside];
            if ([tag.color isEqualToString:@""] || [tag.color isEqualToString:kColorYellowString] || [tag.color isEqualToString:kColorLightBlueString]) {
                tagButton.layer.borderColor = [UIColor colorWithWhite:.90 alpha:1].CGColor;
                [tagButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            } else {
                tagButton.layer.borderColor = [UIColor clearColor].CGColor;
                [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
           
            [tagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
            CGFloat fontSize = 14;
            CGFloat tagPostsCount = [tag.postsCount floatValue];
            
            fontSize += tagPostsCount*2;
            [tagButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:fontSize]];
            CGSize stringSize = [tagButton.titleLabel.text sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:fontSize]];
            
            if (previousOriginX+previousButtonSize+stringSize.width+20 < 320){
                [tagButton setFrame:CGRectMake(previousOriginX+previousButtonSize,previousOriginY-tagPostsCount,stringSize.width+20,(rowHeight+tagPostsCount*2))];
            } else {
                previousOriginX = 0;
                previousButtonSize = 0;
                previousOriginY += (34+tagPostsCount);
                [tagButton setFrame:CGRectMake(0,previousOriginY,stringSize.width+20,(rowHeight+tagPostsCount*2))];
                if (self.tagContainerView.frame.size.height < tagButton.frame.origin.y+(rowHeight+tagPostsCount*2)) {
                    rowIndex++;
                    rowHeight = 34;
                }
            }
            
            previousButtonSize = tagButton.frame.size.width + 5;
            previousOriginX = tagButton.frame.origin.x;
            tagButton.layer.borderWidth = 1.0f;
            tagButton.layer.cornerRadius = tagButton.frame.size.height/2;
            tagButton.layer.shouldRasterize = YES;
            tagButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
            [self.tagContainerView addSubview:tagButton];
        }
        /*if (maxTag){
            [self.maxTagLabel setText:[NSString stringWithFormat:@"\"%@\" was a running theme (%i times). \"%@\" wasn't far behind (%i times).",maxTag.name,maxTagCount,secondTag.name,secondTagCount]];
        }*/
        [self setRows:rowIndex];
    }
}

- (UIColor*)setTagColor:(NSString*)tagColor andAlpha:(CGFloat)alpha {
    if ([tagColor isEqualToString:kColorBlackString]){
        return [UIColor colorWithRed:61/255.0f green:57/255.0f blue:80/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorYellowString]){
        return [UIColor colorWithRed:247/255.0f green:231/255.0f blue:181/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorRedString]){
        return [UIColor colorWithRed:220/255.0f green:79/255.0f blue:35/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorGreenString]){
        return [UIColor colorWithRed:111/255.0f green:182/255.0f blue:86/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorPurpleString]){
        return [UIColor colorWithRed:111/255.0f green:57/255.0f blue:142/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorOrangeString]) {
        return [UIColor colorWithRed:255/255.0f green:156/255.0f blue:62/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorLightBlueString]) {
        return [UIColor colorWithRed:165/255.0f green:215/255.0f blue:254/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorBrownString]) {
        return [UIColor colorWithRed:126/255.0f green:86/255.0f blue:66/255.0f alpha:alpha];
    } else return [UIColor colorWithWhite:.95 alpha:alpha];
}

- (void)showPostsForTag:(UIButton*)tagButton {
    [self performSegueWithIdentifier:@"ShowPostsForTag" sender:tagButton];
}

- (void)setRows:(int)index {
    [self.tagContainerView setFrame:CGRectMake(0, self.tagContainerView.frame.origin.y, 320, 44*index+1)];
    self.tableView.tableFooterView = self.tagContainerView;
    self.tableView.tableHeaderView = self.mapContainerView;
}

- (void)showPostsOnMap {
    homeCount = 0;
    [self.mapView setShowsUserLocation:YES];
    [self.mapView removeAnnotations:self.mapView.annotations];
    if (posts.count == 0) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
    } else {
        [self.mapView addAnnotations:posts];
        for (FDPost *post in posts) {
            if ([post.locationName isEqualToString:@"Home"]) homeCount++;
        }
        /*if (homeCount == 1){
            [self.homeStatsLabel setText:[NSString stringWithFormat:@"I had %i meal at home in the last %@.",homeCount,self.timePeriod]];
        } else if(homeCount > 1) {
            [self.homeStatsLabel setText:[NSString stringWithFormat:@"I had %i meals at home in the last %@.",homeCount,self.timePeriod]];
        }*/
        CLLocationCoordinate2D topLeftCoord;
        topLeftCoord.latitude = -90;
        topLeftCoord.longitude = 180;
        
        CLLocationCoordinate2D bottomRightCoord;
        bottomRightCoord.latitude = 90;
        bottomRightCoord.longitude = -180;
        
        for(id<MKAnnotation> annotation in self.mapView.annotations) {
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
        }
        
        MKCoordinateRegion region;
        region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.25;
        region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.25;
        region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.0;
        
        // Add a little extra space on the sides
        region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.0;
        
        region = [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:YES];
        [self setRows:rowIndex];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return filteredTagsForTagNames.count;
    else if (section == 0) return 4;
    else {
        totalRowNumber = 4 + tagsForTracking.count;
        return totalRowNumber;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TagsCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    cell.textLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellEditingStyleDelete;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [cell.textLabel setText:[[filteredTagsForTagNames objectAtIndex:indexPath.row] name]];
    } else if (indexPath.section == 0){
        if ([categoryCountDict objectForKey:@"eating_count"]) {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = [NSString stringWithFormat:@"Eating: %@ posts", [categoryCountDict objectForKey:@"eating_count"]];
                    break;
                case 1:
                    cell.textLabel.text = [NSString stringWithFormat:@"Drinking: %@ posts", [categoryCountDict objectForKey:@"drinking_count"]];
                    break;
                case 2:
                    cell.textLabel.text = [NSString stringWithFormat:@"Making: %@ posts", [categoryCountDict objectForKey:@"making_count"]];
                    break;
                case 3:
                    cell.textLabel.text = [NSString stringWithFormat:@"Shopping: %@ posts", [categoryCountDict objectForKey:@"shopping_count"]];
                default:
                    break;
            }
        }
    } else {
        if (indexPath.row <= 2) {
            [cell.textLabel setTextColor:[UIColor darkGrayColor]];
            switch (indexPath.row) {
                case 0:
                    //home count should have already been set when the map was drawn
                    if (homeCount == 1){
                        [cell.textLabel setText:[NSString stringWithFormat:@"I had %i meal at home in the last %@.",homeCount,self.timePeriod]];
                    } else if(homeCount > 1) {
                        [cell.textLabel setText:[NSString stringWithFormat:@"I had %i meals at home in the last %@.",homeCount,self.timePeriod]];
                    }
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                case 1:
                    if (maxTag){
                        cell.textLabel.text = [NSString stringWithFormat:@"\"%@\" was a running theme (%i times).",maxTag.name,maxTagCount];
                        //[cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
                    } else {
                        [cell.textLabel setText:@"Your tag cloud is empty right now!"];
                    }
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                case 2:
                    if (secondTag) {
                        cell.textLabel.text = [NSString stringWithFormat:@"\"%@\" wasn't far behind (%i times).",secondTag.name, secondTagCount];
                        //[cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
                    } else {
                        [cell.textLabel setText:@"Tap the \"+\" button on your home screen and start organizing your food life."];
                    }
                    cell.accessoryType = UITableViewCellAccessoryNone;
                default:
                    break;
            }
        } else if (indexPath.row == totalRowNumber - 1){
            [cell.textLabel setText:@"Tap to track a specific tag"];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        } else {
            FDFoodiaTag *thisTag = [tagsForTracking objectAtIndex:(indexPath.row - 3)];
            if (thisTag.postsCount == [NSNumber numberWithInt:0]){
                [cell.textLabel setText:[NSString stringWithFormat:@"I haven't had any %@ in the past %@.",thisTag.name,self.timePeriod]];
            } else if (thisTag.postsCount == [NSNumber numberWithInt:1]) {
                [cell.textLabel setText:[NSString stringWithFormat:@"I've had %@ once in the past %@.",thisTag.name,self.timePeriod]];
            } else {
                [cell.textLabel setText:[NSString stringWithFormat:@"I've had %@ %@ times in the last %@.",thisTag.name,thisTag.postsCount, self.timePeriod]];
            }
            
        }
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView)return 60;
    else return 66;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        tagToTrack = [filteredTagsForTagNames objectAtIndex:indexPath.row];
        [[[UIAlertView alloc] initWithTitle:@"Just to confirm..." message:[NSString stringWithFormat:@"Do you want to start tracking \"%@\"?", tagToTrack.name] delegate:self cancelButtonTitle:@"Nope" otherButtonTitles:@"Yes", nil] show];
    } else if (indexPath.section == 0){
        switch (indexPath.row) {
            case 0:
                _categoryName = kEating;
                break;
            case 1:
                _categoryName = kDrinking;
                break;
            case 2:
                _categoryName = kMaking;
                break;
            case 3:
                _categoryName = kShopping;
            default:
                break;
        }
        [self performSegueWithIdentifier:@"ShowPostsForCategory" sender:self];
    } else if (indexPath.row == totalRowNumber - 1) {
        [UIView animateWithDuration:.2 animations:^{
            self.searchDisplayController.searchBar.transform = CGAffineTransformMakeTranslation(-320, 0);
            self.searchDisplayController.searchResultsTableView.transform = CGAffineTransformMakeTranslation(-320, 0);
            [self.searchDisplayController.searchBar becomeFirstResponder];
        } completion:^(BOOL finished) {
            
        }];
    } else if (indexPath.row > 2) {
        /*tagForRemoval = [tagsForTracking objectAtIndex:(indexPath.row - 3)];
        [[[UIAlertView alloc] initWithTitle:@"Whoa there!" message:[NSString stringWithFormat:@"Are you sure you want to stop tracking \"%@\"?",tagForRemoval.name] delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"I'm sure", nil] show];*/
        UIButton *dummyButton = [[UIButton alloc] init];
        [dummyButton setTitle:[[tagsForTracking objectAtIndex:(indexPath.row - 3)] name] forState:UIControlStateNormal];
        [self performSegueWithIdentifier:@"ShowPostsForTag" sender:dummyButton];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row > 2 && indexPath.row != totalRowNumber - 1)
        return YES;
    else
        return NO;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        tagForRemoval = [tagsForTracking objectAtIndex:indexPath.row-3];
        [[[UIAlertView alloc] initWithTitle:@"Whoa there!" message:[NSString stringWithFormat:@"Are you sure you want to stop tracking \"%@\"?",tagForRemoval.name] delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"I'm sure", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [[FDAPIClient sharedClient] trackTag:tagToTrack.name success:^(id result) {
            [[FDAPIClient sharedClient] getTrackedTagsForTimePeriod:self.timePeriod success:^(id result) {
                tagsForTracking = [result mutableCopy];
                [self.tableView reloadData];
            } failure:^(NSError *error) {}];
        } failure:^(NSError *error) {}];
        [self.searchDisplayController setActive:NO animated:NO];
        self.searchDisplayController.searchBar.transform = CGAffineTransformIdentity;
        self.searchDisplayController.searchResultsTableView.transform = CGAffineTransformIdentity;
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"I'm sure"]){
        [[FDAPIClient sharedClient] removeTrackedTag:tagForRemoval.identifier success:^(id result) {
            [tagsForTracking removeObject:tagForRemoval];
            totalRowNumber --;
            tagForRemoval = nil;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            
        }];
    }
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
    //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [UIView animateWithDuration:.2 animations:^{
        self.searchDisplayController.searchBar.transform = CGAffineTransformIdentity;
        self.searchDisplayController.searchResultsTableView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    //Update the filtered array based on the search text and scope.
    [filteredTagsForTagNames removeAllObjects]; // First clear the filtered array.
    
    // Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
    for (FDFoodiaTag *tag in tagsForTagNames) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:tag.name]) {
            [filteredTagsForTagNames addObject:tag];
        }
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"FoodiaPin"];
    if (view == nil) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FoodiaPin"];
        //[view setImage:[UIImage imageNamed:@"foodiaPin.png"]];
        view.canShowCallout = YES;
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [selectButton addTarget:self action:@selector(tappedVenueButton:) forControlEvents:UIControlEventTouchUpInside];
        view.rightCalloutAccessoryView = selectButton;
    }
    
    UIButton *selectButton = (UIButton *)view.rightCalloutAccessoryView;
    selectButton.tag = [posts indexOfObject:annotation];
    return view;
}

- (IBAction)revealMenu:(UIBarButtonItem *)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
    [(FDMenuViewController*)self.slidingViewController.underLeftViewController refresh];
    [(FDAppDelegate *)[UIApplication sharedApplication].delegate hideLoadingOverlay];
}

- (void)tappedVenueButton:(UIButton*)button {
    [self performSegueWithIdentifier:@"ShowPostFromFoodView" sender:button];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UIButton*)button {
    if ([[segue identifier] isEqualToString:@"ShowPostFromFoodView"]){
        FDPost *post = [posts objectAtIndex:button.tag];
        [(FDPostViewController*)[segue destinationViewController] setPostIdentifier:post.identifier ];
    } else if ([segue.identifier isEqualToString:@"ShowPostsForTag"]) {
        FDPostsTagsViewController *postsVC = segue.destinationViewController;
        [postsVC setUniversal:NO];
        [postsVC setTagName:button.titleLabel.text];
    } else if ([segue.identifier isEqualToString:@"ShowPostsForCategory"]) {
        FDCategoryPostsViewController *vc = segue.destinationViewController;
        [vc setTimePeriod:_timePeriod];
        [vc setCategoryName:_categoryName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
