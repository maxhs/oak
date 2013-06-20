//
//  FDPhotoLibraryCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 4/28/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDPhotoLibraryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
- (void)configureForAssets:(NSMutableArray *)photoAssets;
@end
