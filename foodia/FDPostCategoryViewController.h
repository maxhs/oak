//
//  FDPostCategoryViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPost.h"

@interface FDPostCategoryViewController : UIViewController
@property (nonatomic, strong) UIImage *dummyImage;
@property BOOL isEditingPost;
@property (strong, nonatomic) FDPost *thePost;
@end
