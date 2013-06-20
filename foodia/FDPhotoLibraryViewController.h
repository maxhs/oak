//
//  FDPhotoLibraryViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 4/28/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface FDPhotoLibraryViewController : UITableViewController
@property BOOL shouldBeEditing;
@end
