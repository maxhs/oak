//
//  FDFoodiaTagsViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/18/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDFoodiaTagsViewController.h"
#import "FDAPIClient.h"
#import "FDFoodiaTag.h"
#import "FDPost.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"

NSString *const kPlaceholderTagPrompt = @"Add a tag...";

@interface FDFoodiaTagsViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate> {
    int previousOriginX;
    int previousOriginY;
    int previousButtonSize;
    UIButton *tagButtonToRemove;
    NSMutableArray *tagSearchResults;
    UISearchBar *searchBar;
}
@property (strong, nonatomic) AFHTTPRequestOperation *tagSearchRequestOperation;
@property (weak, nonatomic) IBOutlet UIView *tagContainerView;
@end

@implementation FDFoodiaTagsViewController

@synthesize allTags = _allTags;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Adding tags to new post" timed:YES];
    tagSearchResults = [NSMutableArray array];
    if (FDPost.userPost.tagArray.count){
        self.allTags = FDPost.userPost.tagArray;
        [self refreshTags];
    } else {
        self.allTags = [NSMutableArray array];
        [self getTags];
    }
    
    searchBar = [[UISearchBar alloc] init];
    self.navigationItem.titleView = searchBar;
    [searchBar setFrame:CGRectMake(60, 0, 260, 44)];
    searchBar.placeholder = kPlaceholderTagPrompt;
    [searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
    [searchBar setDelegate:self];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        for (UIView *view in searchBar.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
                UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tallFoodiaHeader.png"]];
                [view addSubview:header];
                break;
            }
        }
    } else {
        for (UIView *view in searchBar.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
                UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newFoodiaHeader.png"]];
                [view addSubview:header];
                break;
            }
        }
    }
    for(UIView *subView in searchBar.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subView;
            searchField.font = [UIFont fontWithName:kHelveticaNeueThin size:16];
        }
    }
}

- (void)getTags {
    [[FDAPIClient sharedClient] getTagsForFoodiaObject:FDPost.userPost.foodiaObject success:^(NSArray *result) {
        [self.allTags addObjectsFromArray:result];
        [self refreshTags];
    } failure:^(NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    FDPost.userPost.foodiaObject = textField.text;
}

- (void)refreshTags {
    previousOriginX = 44;
    previousButtonSize = 0;
    previousOriginY = 5;
    [self.tagContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIImageView *tagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag"]];
    [self.tagContainerView addSubview:tagImageView];
    [tagImageView setFrame:CGRectMake(6, 8, 26, 26)];
    for (FDFoodiaTag *tag in self.allTags){
        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tagButton setTitle:[NSString stringWithFormat:@"#%@",tag.name] forState:UIControlStateNormal];
        [tagButton addTarget:self action:@selector(removeTag:) forControlEvents:UIControlEventTouchUpInside];
        [tagButton setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
        tagButton.layer.shadowColor = [UIColor lightGrayColor].CGColor;
        tagButton.layer.shadowRadius = 2.5f;
        tagButton.layer.shadowOffset = CGSizeMake(0,0);
        tagButton.layer.shadowOpacity = .4f;
        tagButton.layer.borderColor = [UIColor colorWithWhite:.90 alpha:1].CGColor;
        tagButton.layer.borderWidth = 1.0f;
        tagButton.layer.cornerRadius = 17.0f;
        [tagButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [tagButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
        CGSize stringSize = [tagButton.titleLabel.text sizeWithFont:[UIFont fontWithName:kHelveticaNeueThin size:15]];
        [tagButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        if (previousOriginX+previousButtonSize+stringSize.width+20 < 320){
            [tagButton setFrame:CGRectMake(previousOriginX+previousButtonSize,previousOriginY,stringSize.width+20,34)];
        } else {
            previousOriginX = 0;
            previousButtonSize = 0;
            previousOriginY += 44;
            [tagButton setFrame:CGRectMake(0,previousOriginY,stringSize.width+20,34)];
            if (self.tagContainerView.frame.size.height < tagButton.frame.origin.y+34) [self expandContainerView];
        }
        previousButtonSize = tagButton.frame.size.width + 5;
        previousOriginX = tagButton.frame.origin.x;
        [self.tagContainerView addSubview:tagButton];
    }
}

- (void)expandContainerView {
    [UIView animateWithDuration:.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.tagContainerView setFrame:CGRectMake(0, 0, 320, self.tagContainerView.frame.size.height+44)];
        [self.tableView setFrame:CGRectMake(0, self.tagContainerView.frame.size.height, 320, self.tableView.frame.size.height-44)];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)removeTag:(UIButton*)button {
    [[[UIAlertView alloc] initWithTitle:@"Wait a sec?" message:@"Are you sure you want to remove this tag?" delegate:self cancelButtonTitle:@"Nope" otherButtonTitles:@"Yes, I'm sure", nil] show];
    tagButtonToRemove = button;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes, I'm sure"]) {
        NSMutableArray *tempArray = [NSMutableArray array];
        for (FDFoodiaTag *tag in self.allTags) {
            if (![[NSString stringWithFormat:@"#%@",tag.name] isEqualToString:tagButtonToRemove.titleLabel.text]){
                [tempArray addObject:tag];
            }
        }
        self.allTags = tempArray;
        [self refreshTags];
    }
}

- (void)startSearchRequest:(NSString*)query {
    [self.tagSearchRequestOperation cancel];
    RequestSuccess success = ^(NSArray *result) {
        if (result.count){
            tagSearchResults = [result mutableCopy];
        } else {
            [tagSearchResults removeAllObjects];
        }
        [self.tableView reloadData];
    };
    RequestFailure failure = ^(NSError *error) {
        //NSLog(@"Error finding tags! %@", error.description);
    };
    [self.tableView reloadData];
    AFHTTPRequestOperation *op;
    op = [[FDAPIClient sharedClient] getSearchResultsForTagQuery:query
                                                         success:success
                                                         failure:failure];
    self.tagSearchRequestOperation = op;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)search {
    [search setText:@""];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 1) {
        [self startSearchRequest:searchText];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)search {
    [self startSearchRequest:search.text];
    [searchBar endEditing:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)search {
    [self.tagSearchRequestOperation cancel];
    [searchBar endEditing:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)search {
    [self.tableView reloadData];
    [searchBar endEditing:YES];
    if (search.text.length == 0) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
            [searchBar setText:kPlaceholderTagPrompt];
        } else {
            [searchBar setText:kPlaceholderTagPrompt];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (searchBar.text.length && ![searchBar.text isEqualToString:kPlaceholderTagPrompt]) return tagSearchResults.count + 1;
    else return tagSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < tagSearchResults.count) {
        //FDFoodiaTag *tag = [self.tagSearchResults objectAtIndex:indexPath.row];
        NSString *tagName = [tagSearchResults objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell"];
        cell.textLabel.text = tagName;
        return cell;
    } else {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"AddTagCell"];
        if (searchBar.text.length && ![searchBar.text isEqualToString:kPlaceholderTagPrompt]) cell.textLabel.text = [NSString stringWithFormat:@"Add a new tag: \"%@\"", searchBar.text];
        else [cell.textLabel setText:@""];
        return cell;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < tagSearchResults.count) {
        FDFoodiaTag *tag = [[FDFoodiaTag alloc] initWithDictionary:@{@"name":[tagSearchResults objectAtIndex:indexPath.row],@"userId":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}];
        [self.allTags addObject:tag];
    } else {
        FDFoodiaTag *newTag = [[FDFoodiaTag alloc] initWithDictionary:@{@"name":searchBar.text,@"userId":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}];
        [self.allTags addObject:newTag];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [searchBar setText:kPlaceholderTagPrompt];
    [tagSearchResults removeAllObjects];
    [self.tableView reloadData];
    [searchBar endEditing:YES];
    [self refreshTags];
}

#pragma mark - Back

- (void)viewWillDisappear:(BOOL)animated {
    [searchBar endEditing:YES];
    [FDPost.userPost setTagArray:self.allTags];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.view endEditing:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateNewPostVC" object:nil];
}

@end
