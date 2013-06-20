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
    NSMutableArray *tags;
    FDFoodiaTag *maxTag;
    int maxTagCount;
    FDFoodiaTag *secongTag;
    int secondTagCount;
}

@property (weak, nonatomic) IBOutlet UIButton *weekButton;
@property (weak, nonatomic) IBOutlet UIButton *monthButton;
@property (weak, nonatomic) IBOutlet UIButton *yearButton;
@property (weak, nonatomic) IBOutlet UIView *tagContainerView;
@property (weak, nonatomic) IBOutlet UILabel *homeStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxTagLabel;
-(IBAction)week;
-(IBAction)month;
-(IBAction)year;
-(IBAction)rightBarButtonAction;
@end

@implementation FDFoodViewController

@synthesize categoryName = _categoryName, timePeriod = _timePeriod;

- (void)viewDidLoad
{
    self.tableView.tableHeaderView = self.mapContainerView;
    self.tableView.tableFooterView = self.tagContainerView;
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [Flurry logEvent:@"Viewing My Digest" timed:YES];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,180,44);
    navTitle.text = @"Digest";
    navTitle.font = [UIFont fontWithName:kHelveticaNeueThin size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    categoryCountDict = [NSMutableDictionary dictionary];
    posts = [NSMutableArray array];
    tags = [NSMutableArray array];
    
    if ([UIScreen mainScreen].bounds.size.height == 568) iPhone5 = YES;
    else iPhone5 = NO;

    // Set label as titleView
    self.navigationItem.titleView = navTitle;
    
    [self resetMapForTimePeriod:kWeek];
    [self getCategoryCountsForTimePeriod:kWeek];
    [self getTagsForTimePeriod:kWeek];
    _timePeriod = kWeek;
    [self selectTimeButton:self.weekButton];
    rowIndex = 1;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
        NSLog(@"Failure from time period method: %@",error.description);
    }];
    [self getTagsForTimePeriod:timePeriod];
}

- (void)getTagsForTimePeriod:(NSString*)timePeriod{
    [[FDAPIClient sharedClient] getTagsForTimePeriod:timePeriod success:^(id result) {
        tags = result;
        [self refreshTags];
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
    if (tags.count){
        CGFloat rowHeight = 34;
        for (FDFoodiaTag *tag in tags){
            //reset alpha to baseline for each tag
            CGFloat alpha = 0.5f;
            
            //get info for the tag label
            if ([tag.postsCount intValue] >= maxTagCount) {
                if (maxTag) {
                    secongTag = maxTag;
                    secondTagCount = maxTagCount;
                }
                maxTag = tag;
                maxTagCount = [tag.postsCount intValue];
            }
            
            UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
            alpha += (.1 * [tag.postsCount floatValue]);
            [tagButton setBackgroundColor:[self setTagColor:tag.color andAlpha:alpha]];
            [tagButton addTarget:self action:@selector(showPostsForTag:) forControlEvents:UIControlEventTouchUpInside];
            if ([tag.color isEqualToString:@""] || [tag.color isEqualToString:kColorGrainString] || [tag.color isEqualToString:kColorLiquidString]) {
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
        if (maxTag){
            [self.maxTagLabel setText:[NSString stringWithFormat:@"\"%@\" was a running theme (%i times). \"%@\" wasn't far behind (%i times).",maxTag.name,maxTagCount,secongTag.name,secondTagCount]];
        }
        
        [self setRows:rowIndex];
    } else {
        UILabel *tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, previousOriginY,320,34)];
        [tagLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
        [tagLabel setTextAlignment:NSTextAlignmentCenter];
        [tagLabel setTextColor:[UIColor lightGrayColor]];
        [tagLabel setText:@"Your tag cloud is empty right now!"];
        [tagLabel setBackgroundColor:[UIColor clearColor]];
        [self.tagContainerView addSubview:tagLabel];
        [self.maxTagLabel setTextColor:[UIColor darkGrayColor]];
        [self.maxTagLabel setTextAlignment:NSTextAlignmentCenter];
        [self.maxTagLabel setText:@"Tap the \"+\" button on your home screen to start organizing your food life."];
    }
}

- (UIColor*)setTagColor:(NSString*)tagColor andAlpha:(CGFloat)alpha {
    if ([tagColor isEqualToString:kColorLiquorString]){
        return [UIColor colorWithRed:61/255.0f green:57/255.0f blue:80/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorGrainString]){
        return [UIColor colorWithRed:247/255.0f green:231/255.0f blue:181/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorMeatString]){
        return [UIColor colorWithRed:220/255.0f green:79/255.0f blue:35/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorGreenString]){
        return [UIColor colorWithRed:111/255.0f green:182/255.0f blue:86/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorPurpleString]){
        return [UIColor colorWithRed:111/255.0f green:57/255.0f blue:142/255.0f alpha:alpha];
    } else if ([tagColor isEqualToString:kColorOrangeString]) {
        return [UIColor colorWithRed:255/255.0f green:156/255.0f blue:62/255.0f alpha:1.0f];
    } else if ([tagColor isEqualToString:kColorLiquidString]) {
        return [UIColor colorWithRed:165/255.0f green:215/255.0f blue:254/255.0f alpha:1.0f];
    } else return [UIColor colorWithWhite:.95 alpha:alpha];
}

- (void)showPostsForTag:(UIButton*)tagButton {
    [self performSegueWithIdentifier:@"ShowPostsForTag" sender:tagButton];
}

- (void)setRows:(int)index {
    [self.tagContainerView setFrame:CGRectMake(0, self.tagContainerView.frame.origin.y, 320, 44*index+1)];
    self.tableView.tableHeaderView = self.mapContainerView;
    self.tableView.tableFooterView = self.tagContainerView;
}

- (void)showPostsOnMap {
    homeCount = 0;
    [self.mapView setShowsUserLocation:YES];
    [self.mapView removeAnnotations:self.mapView.annotations];
    if (posts.count == 0) {
        [(FDAppDelegate*)[UIApplication sharedApplication].delegate hideLoadingOverlay];
        [self.homeStatsLabel setText:@"There's nothing to show you yet!"];
        [self.homeStatsLabel setTextAlignment:NSTextAlignmentCenter];
        [self.homeStatsLabel setTextColor:[UIColor darkGrayColor]];
    } else {
        [self.mapView addAnnotations:posts];
        for (FDPost *post in posts) {
            if ([post.locationName isEqualToString:@"Home"]) homeCount++;
        }
        if (homeCount == 1){
            [self.homeStatsLabel setText:[NSString stringWithFormat:@"I had %i meal at home in the last %@.",homeCount,self.timePeriod]];
        } else if(homeCount > 1) {
            [self.homeStatsLabel setText:[NSString stringWithFormat:@"I had %i meals at home in the last %@.",homeCount,self.timePeriod]];
        }
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TagsCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:16]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([categoryCountDict objectForKey:@"eating_count"]){
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = [NSString stringWithFormat:@"EATING - %@ posts", [categoryCountDict objectForKey:@"eating_count"]];
                break;
            case 1:
                cell.textLabel.text = [NSString stringWithFormat:@"DRINKING - %@ posts", [categoryCountDict objectForKey:@"drinking_count"]];
                break;
            case 2:
                cell.textLabel.text = [NSString stringWithFormat:@"MAKING - %@ posts", [categoryCountDict objectForKey:@"making_count"]];
                break;
            case 3:
                cell.textLabel.text = [NSString stringWithFormat:@"SHOPPING - %@ posts", [categoryCountDict objectForKey:@"shopping_count"]];
            default:
                break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
