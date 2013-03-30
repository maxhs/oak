//
//  FDPostGridCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/2/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDPostGridCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackground;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackground1;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackground2;
- (void)configureForPost:(NSMutableArray *)cellPosts;
+ (CGFloat)cellHeight;

@end

@class FDPost;