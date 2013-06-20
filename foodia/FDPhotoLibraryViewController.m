//
//  FDPhotoLibraryViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 4/28/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPhotoLibraryViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "FDPhotoLibraryCell.h"
#import "FDPost.h"
#import "FDAppDelegate.h"
#import "FDCameraViewController.h"

@interface FDPhotoLibraryViewController () {
    NSArray *photoAssets;
    ALAssetsLibrary *library;
}
@end

@implementation FDPhotoLibraryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    photoAssets = [NSArray array];
    NSMutableArray *tempArray = [NSMutableArray array];
    library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [tempArray addObject:result];
                /*ALAssetRepresentation *rep = [result defaultRepresentation];
                CGImageRef iref = [rep fullResolutionImage];
                if (iref) {
                    //[self.photos addObject:[UIImage imageWithCGImage:iref]];
                }*/
            }
            
        }];
        photoAssets = [NSArray arrayWithArray:tempArray];
        photoAssets = [[photoAssets reverseObjectEnumerator] allObjects];
        [self.tableView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"error getting photos: %@",error.description);
    }];
    UILabel *navTitle = [[UILabel alloc] init];
    navTitle.frame = CGRectMake(0,0,180,44);
    navTitle.text = @"My photos";
    navTitle.font = [UIFont fontWithName:kHelveticaNeueThin size:20];
    navTitle.backgroundColor = [UIColor clearColor];
    navTitle.textColor = [UIColor blackColor];
    navTitle.textAlignment = NSTextAlignmentCenter;
    
    // Set label as titleView
    self.navigationItem.titleView = navTitle;

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    double amt = photoAssets.count / 4;
    amt = ceil(amt);
    NSInteger tmp = amt;
    return tmp;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FDPhotoLibraryCell *cell = (FDPhotoLibraryCell *)[tableView dequeueReusableCellWithIdentifier:@"PhotoLibraryCell"];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FDPhotoLibraryCell" owner:self options:nil];
        cell = (FDPhotoLibraryCell *)[nib objectAtIndex:0];
    }
    
    ALAsset *asset1 = [photoAssets objectAtIndex:(indexPath.row*4)];
    ALAsset *asset2 = [photoAssets objectAtIndex:(indexPath.row*4)+1];
    ALAsset *asset3 = [photoAssets objectAtIndex:(indexPath.row*4)+2];
    ALAsset *asset4 = [photoAssets objectAtIndex:(indexPath.row*4)+3];
    NSMutableArray *cellAssets = [NSMutableArray arrayWithObjects:asset1, asset2, asset3, asset4, nil];
    [cell configureForAssets:cellAssets];
    [cell.button1 addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button1 setTag:indexPath.row*4];
    [cell.button2 addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 setTag:indexPath.row*4+1];
    [cell.button3 addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button3 setTag:indexPath.row*4+2];
    [cell.button4 addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button4 setTag:indexPath.row*4+3];
    return cell;

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

-(void)selectImage:(id)sender {
    UIButton *button = (UIButton*)sender;
    ALAsset *asset = [photoAssets objectAtIndex:button.tag];
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    // Retrieve the image orientation from the ALAsset
    UIImageOrientation orientation = UIImageOrientationUp;
    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
    if (orientationValue != nil) {
        orientation = [orientationValue intValue];
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:[rep fullResolutionImage] scale:0.5 orientation:orientation];
    if (self.shouldBeEditing){
        FDCameraViewController *vc = (FDCameraViewController*)self.presentingViewController;
        vc.isPreview = YES;
        [vc.photoPreviewImageView setImage:image];
        [vc setCropImage:image];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        FDCameraViewController *vc = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        vc.isPreview = YES;
        [vc.photoPreviewImageView setImage:image];
        [vc setCropImage:image];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    FDCameraViewController *vc = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-1];
    [vc.filterScrollView setHidden:NO];
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

/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
 
}*/

@end
