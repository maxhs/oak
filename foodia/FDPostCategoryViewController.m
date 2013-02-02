//
//  FDPostCategoryViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostCategoryViewController.h"
#import "AFNetworking.h"
#import "FDAPIClient.h"
#import "FDCache.h"
#import "FDPost.h"
#import "UIButton+WebCache.h"
#import "SDImageCache.h"
#import <QuartzCore/QuartzCore.h>

@interface FDPostCategoryViewController () <UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *dummyView;
@property (nonatomic, weak) IBOutlet UIView *eatingContainerView;
@property (nonatomic, weak) IBOutlet UIView *drinkingContainerView;
@property (nonatomic, weak) IBOutlet UIView *shoppingContainerView;
@property (nonatomic, weak) IBOutlet UIView *makingContainerView;
@property (nonatomic, weak) IBOutlet UIView *makingTitleView;
@property (nonatomic, weak) IBOutlet UIView *eatingTitleView;
@property (nonatomic, weak) IBOutlet UIView *shoppingTitleView;
@property (nonatomic, weak) IBOutlet UIView *drinkingTitleView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIImageView *textFieldImageView;
@property (nonatomic, weak) IBOutlet UITextField *objectTextField;
@property (nonatomic, weak) IBOutlet UITableView *searchResultsTableView;
@property (nonatomic, strong) NSTimer       *searchTimer;
@property (nonatomic, strong) NSArray       *searchResults;
@property (nonatomic, strong) NSMutableSet  *buttons;
@property (nonatomic, strong) NSTimer       *categoryImageTimer;
@property (nonatomic, strong) NSDictionary  *categoryImageURLs;
@property (nonatomic, strong) NSString      *objectType;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButtonItem;

@property (nonatomic, strong) AFHTTPRequestOperation *categoryImageRequestOpertaion;
@property (nonatomic, strong) AFHTTPRequestOperation *objectSearchRequestOperation;
- (void)showCategories;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)selectEat:(id)sender;
- (IBAction)selectMake:(id)sender;
- (IBAction)selectDrink:(id)sender;
- (IBAction)selectShop:(id)sender;
- (IBAction)clearTextField:(id)sender;
- (IBAction)textFieldDidChange:(id)sender;
- (UIButton *)setupButtonForContainer:(UIView *)containerView
                            titleView:(UIView *)titleView
                     placeholderImage:(UIImage *)placeholderImage
                             imageUrl:(NSURL *)imageUrl
                                delay:(float)delay;
@end

@implementation FDPostCategoryViewController

@synthesize dummyView;
@synthesize eatingContainerView;
@synthesize drinkingContainerView;
@synthesize shoppingContainerView;
@synthesize makingContainerView;
@synthesize makingTitleView;
@synthesize eatingTitleView;
@synthesize shoppingTitleView;
@synthesize drinkingTitleView;
@synthesize cameraButton;
@synthesize doneButton;
@synthesize plusButton;
@synthesize clearButton;
@synthesize textFieldImageView;
@synthesize objectTextField;
@synthesize searchResultsTableView;
@synthesize dummyImage;
@synthesize searchTimer;
@synthesize searchResults;
@synthesize buttons;
@synthesize categoryImageTimer;
@synthesize categoryImageURLs;
@synthesize nextButtonItem;
@synthesize categoryImageRequestOpertaion;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.categoryImageURLs = [FDCache getCachedCategoryImageURLs];
    if (self.categoryImageURLs == nil || [FDCache isCategoryImageCacheStale]) {
        [self getNewCategoryImages];
    }
    
    /*if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)){
        //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:(@"launchBackground@2x.png")]];
       // dummyImage = [UIImage imageNamed:(@"foodiaHeader.png")];
        
        self.dummyView.backgroundColor = [UIColor colorWithPatternImage:dummyImage];
        self.dummyView.alpha = 1.0;
        self.view.clipsToBounds = NO;
        dummyImage = nil;
        [self hideCategories];
    } else {*/
        if (dummyImage) {
            self.dummyView.alpha = 1.0;
            self.dummyView.image = self.dummyImage;
            if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0)) self.dummyView.frame = CGRectMake(0, -44, 320, 548);
            else self.dummyView.frame = CGRectMake(0, -44, 320, 460);
            self.view.clipsToBounds = NO;
            dummyImage = nil;
            [self hideCategories];
        } else {
            [self showCategories];
        }
    //}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.dummyView.alpha == 1.0) [self showCategories];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.categoryImageRequestOpertaion cancel];
    [self.categoryImageTimer invalidate];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"NewPost"]) {
        FDPost.userPost.foodiaObject = self.objectTextField.text;
    }
}

- (void)viewDidUnload
{
    [self setNextButtonItem:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)getNewCategoryImages {
    self.categoryImageRequestOpertaion = [[FDAPIClient sharedClient] getCategoryImageURLsWithSuccess:^(NSDictionary *result) {
        self.categoryImageURLs = result;
        [FDCache cacheCategoryImageURLs:self.categoryImageURLs];
    } failure:^(NSError *error) {
        NSLog(@"category image update failed! %@", error.description);
    }];
}

- (void)hideCategories {
    self.eatingContainerView.transform    = CGAffineTransformMakeTranslation(320, 0);
    self.drinkingContainerView.transform  = CGAffineTransformMakeTranslation(-320, 0);
    self.makingContainerView.transform   = CGAffineTransformMakeTranslation(320, 0);
    self.shoppingContainerView.transform   = CGAffineTransformMakeTranslation(-320, 0);
}


- (void)showCategories {
    [self loadCategoryImages];
    if (self.dummyView.image == nil) return;
    [UIView animateWithDuration:0.2 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.eatingContainerView.transform = CGAffineTransformMakeTranslation(-20, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.eatingContainerView.transform = CGAffineTransformIdentity;
        }];
        [UIView animateWithDuration:0.2 animations:^{
            self.dummyView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.dummyView.image = nil;
        }];
    }];
    
    [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.drinkingContainerView.transform = CGAffineTransformMakeTranslation(20, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.drinkingContainerView.transform = CGAffineTransformIdentity;
        }];
    }];
    
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.makingContainerView.transform = CGAffineTransformMakeTranslation(-20, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.makingContainerView.transform = CGAffineTransformIdentity;
            
        }];
    }];
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.shoppingContainerView.transform = CGAffineTransformMakeTranslation(20, 0);
        self.plusButton.transform = CGAffineTransformMakeTranslation(-20, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.shoppingContainerView.transform = CGAffineTransformIdentity;
            
        }];
        
    }];
}

- (void)loadCategoryImages {
    NSArray *imageArray;
    NSURL *imageUrl;
    UIButton *button;
    
    NSMutableArray *ordinals = [NSMutableArray arrayWithObjects:@"0", @"1", @"2", @"3", nil];
    for (int i = 0; i < ordinals.count; i++) {
        [ordinals exchangeObjectAtIndex:i withObjectAtIndex:arc4random()%ordinals.count];
    }
    
    imageArray = [self.categoryImageURLs objectForKey:@"Eating"];
    imageUrl = nil;
    if (imageArray.count) {
        imageUrl = [NSURL URLWithString:[imageArray objectAtIndex:arc4random()%imageArray.count]];
    }
    button = [self setupButtonForContainer:self.eatingContainerView titleView:self.eatingTitleView placeholderImage:[UIImage imageNamed:@"category_eat"] imageUrl:imageUrl delay:0.5*[[ordinals objectAtIndex:0] floatValue]];
    [button addTarget:self action:@selector(selectEat:) forControlEvents:UIControlEventTouchUpInside];
    
    imageArray = [self.categoryImageURLs objectForKey:@"Making"];
    imageUrl = nil;
    if (imageArray.count) {
        imageUrl = [NSURL URLWithString:[imageArray objectAtIndex:arc4random()%imageArray.count]];
    }
    button = [self setupButtonForContainer:self.makingContainerView titleView:self.makingTitleView placeholderImage:[UIImage imageNamed:@"category_make"] imageUrl:imageUrl delay:0.5*[[ordinals objectAtIndex:1] floatValue]];
    [button addTarget:self action:@selector(selectMake:) forControlEvents:UIControlEventTouchUpInside];
    
    imageArray = [self.categoryImageURLs objectForKey:@"Drinking"];
    imageUrl = nil;
    if (imageArray.count) {
        imageUrl = [NSURL URLWithString:[imageArray objectAtIndex:arc4random()%imageArray.count]];
    }
    
    button = [self setupButtonForContainer:self.drinkingContainerView titleView:self.drinkingTitleView placeholderImage:[UIImage imageNamed:@"category_drink"] imageUrl:imageUrl delay:0.5*[[ordinals objectAtIndex:2] floatValue]];
    [button addTarget:self action:@selector(selectDrink:) forControlEvents:UIControlEventTouchUpInside];
    
    imageArray = [self.categoryImageURLs objectForKey:@"Shopping"];
    imageUrl = nil;
    if (imageArray.count) {
        imageUrl = [NSURL URLWithString:[imageArray objectAtIndex:arc4random()%imageArray.count]];
    }
    
    button = [self setupButtonForContainer:self.shoppingContainerView titleView:self.shoppingTitleView placeholderImage:[UIImage imageNamed:@"category_shop"] imageUrl:imageUrl delay:0.5*[[ordinals objectAtIndex:3] floatValue]];
    [button addTarget:self action:@selector(selectShop:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.categoryImageTimer invalidate];
    self.categoryImageTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loadCategoryImages) userInfo:nil repeats:NO];
}

- (IBAction)cancel:(id)sender {
    if (self.textFieldImageView.alpha) {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.objectTextField resignFirstResponder];
        [UIView animateWithDuration:0.3 animations:^{
            self.drinkingContainerView.alpha  = 1.0;
            self.makingContainerView.alpha   = 1.0;
            self.shoppingContainerView.alpha   = 1.0;
            self.eatingContainerView.alpha    = 1.0;
            self.shoppingContainerView.transform   = CGAffineTransformIdentity;
            self.makingContainerView.transform   = CGAffineTransformIdentity;
            self.drinkingContainerView.transform  = CGAffineTransformIdentity;
            self.eatingContainerView.transform    = CGAffineTransformIdentity;
            self.textFieldImageView.alpha   = 0.0;
            self.objectTextField.alpha      = 0.0;
            self.cameraButton.alpha         = 1.0;
            self.doneButton.alpha           = 0.0;
            self.clearButton.alpha          = 0.0;
            self.searchResultsTableView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.drinkingContainerView.userInteractionEnabled    = YES;
            self.makingContainerView.userInteractionEnabled     = YES;
            self.shoppingContainerView.userInteractionEnabled    = YES;
            self.eatingContainerView.userInteractionEnabled      = YES;
        }];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction)done:(id)sender {
    
}
- (IBAction)selectEat:(id)sender {
    [self.navigationItem setRightBarButtonItem:nextButtonItem animated:YES];
    self.objectType = @"FoodObject";
    FDPost.userPost.category = @"Eating";
    self.eatingContainerView.userInteractionEnabled = NO;
    self.objectTextField.text = nil;
    self.objectTextField.placeholder = @"What are you eating?";
    [self.objectTextField becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 1.0;
        self.cameraButton.alpha = 0.0;
        self.makingContainerView.alpha = 0.0;
        self.shoppingContainerView.alpha = 0.0;
        self.drinkingContainerView.alpha = 0.0;
        self.eatingContainerView.transform = CGAffineTransformMakeTranslation(0, 6-self.eatingContainerView.frame.origin.y);
    } completion:^(BOOL finished) {
        [self showTextView];
    }];
}
- (IBAction)selectMake:(id)sender {
    [self.navigationItem setRightBarButtonItem:nextButtonItem animated:YES];
    self.objectType = @"FoodObject";
    FDPost.userPost.category = @"Making";
    self.makingContainerView.userInteractionEnabled = NO;
    self.objectTextField.text = nil;
    self.objectTextField.placeholder = @"What are you making?";
    
    [self.objectTextField becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 1.0;
        self.cameraButton.alpha = 0.0;
        self.shoppingContainerView.alpha = 0.0;
        self.eatingContainerView.alpha = 0.0;
        self.drinkingContainerView.alpha = 0.0;
        self.makingContainerView.transform = CGAffineTransformMakeTranslation(0, 6-self.makingContainerView.frame.origin.y);
    } completion:^(BOOL finished) {
        [self showTextView];

    }];
}
- (IBAction)selectDrink:(id)sender {
    [self.navigationItem setRightBarButtonItem:nextButtonItem animated:YES];
    self.objectType = @"DrinkObject";
    FDPost.userPost.category = @"Drinking";
    self.drinkingContainerView.userInteractionEnabled = NO;
    self.objectTextField.text = nil;
    self.objectTextField.placeholder = @"What are you drinking?";
    [self.objectTextField becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 1.0;
        self.cameraButton.alpha = 0.0;
        self.makingContainerView.alpha = 0.0;
        self.shoppingContainerView.alpha = 0.0;
        self.eatingContainerView.alpha = 0.0;
        self.drinkingContainerView.transform = CGAffineTransformMakeTranslation(0, 6-self.drinkingContainerView.frame.origin.y);
    } completion:^(BOOL finished) {
        [self showTextView];

    }];
}
- (IBAction)selectShop:(id)sender {
    [self.navigationItem setRightBarButtonItem:nextButtonItem animated:YES];
    self.objectType = @"ShoppingObject";
    FDPost.userPost.category = @"Shopping";
    self.shoppingContainerView.userInteractionEnabled = NO;
    self.objectTextField.text = nil;
    self.objectTextField.placeholder = @"What are you shopping for?";
    [self.objectTextField becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 1.0;
        self.cameraButton.alpha = 0.0;
        self.makingContainerView.alpha = 0.0;
        self.drinkingContainerView.alpha = 0.0;
        self.eatingContainerView.alpha = 0.0;
        
        self.shoppingContainerView.transform = CGAffineTransformMakeTranslation(0, 6-self.shoppingContainerView.frame.origin.y);
    } completion:^(BOOL finished) {
        [self showTextView];

    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)clearTextField:(id)sender {
    self.objectTextField.text = nil;

}
- (IBAction)textFieldDidChange:(id)sender {
    [self.searchResultsTableView reloadData];
    [self.searchTimer invalidate];
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startSearchRequest) userInfo:nil repeats:NO];
}

- (void)showTextView {
    self.searchResults = nil;
    [self.searchResultsTableView reloadData];
    [self startSearchRequest];
    [UIView animateWithDuration:0.2 animations:^{
        self.textFieldImageView.alpha = 0.9;
        self.objectTextField.alpha = 1.0;
        self.clearButton.alpha = 1.0;
        self.searchResultsTableView.alpha = 1.0;
    }];
}

- (void)startSearchRequest {
    [self.objectSearchRequestOperation cancel];
    
    RequestSuccess success = ^(NSArray *result) {
        self.searchResults = result;
        [self.searchResultsTableView reloadData];
    };
    
    RequestFailure failure = ^(NSError *error) {
            NSLog(@"object search failed! %@", error.description);
    };
    
    AFHTTPRequestOperation *op;
    op = [[FDAPIClient sharedClient] getSearchResultsForObjectCategory:self.objectType
                                                                 query:self.objectTextField.text
                                                               success:success
                                                               failure:failure];
    self.objectSearchRequestOperation = op;

}


- (UIButton *)setupButtonForContainer:(UIView *)containerView
                            titleView:(UIView *)titleView
                     placeholderImage:(UIImage *)placeholderImage
                             imageUrl:(NSURL *)imageUrl
                                delay:(float)delay {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (containerView.subviews.count == 1) {
        button.frame = containerView.bounds;
        [containerView addSubview:button];
        [containerView bringSubviewToFront:titleView];
        UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageUrl.absoluteString];
        if (image)
            [button setImage:image forState:UIControlStateNormal];
        else
            [button setImage:placeholderImage forState:UIControlStateNormal];
    } else {
        button.alpha = 0;
        button.frame = containerView.bounds;
        [containerView addSubview:button];
        [containerView bringSubviewToFront:titleView];
        [self.buttons addObject:button];
        __weak UIButton *_button = button;
        
        
        [button setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [UIView animateWithDuration:0.8 delay:delay options:0 animations:^{
                [button setAlpha:1.0f];
            } completion:^(BOOL finished) {
                // after fading in the new button, remove any old ones behind it
                // using weak reference to button to avoid leaking it. thanks, ARC warning
                for (UIView *subview in containerView.subviews) {
                    if ([containerView.subviews indexOfObject:subview] < [containerView.subviews indexOfObject:_button]) {
                        [subview removeFromSuperview];
                    }
                }
            }];
        }];
    }
    
    return button;

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == [self.searchResults count]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Add \"%@\"", self.objectTextField.text];
    }
    else cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.row == [self.searchResults count]) {
    } else {
        self.objectTextField.text = [self.searchResults objectAtIndex:indexPath.row];
    }
    [self performSegueWithIdentifier:@"NewPost" sender:nil];
}

@end
