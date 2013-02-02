//
//  FDPostNearbyCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 10/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@class FDPost;

@interface FDPostNearbyCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *posterButton;
@property (weak, nonatomic) NSString *userId;

- (void)configureForPost:(FDPost *)post;
+ (CGFloat)cellHeight;

@end
