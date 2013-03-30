//
//  FDPostCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 7/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@class FDPost;

@interface FDPostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UILabel *socialLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) NSString *userId;
@property (weak, nonatomic) IBOutlet UIButton *posterButton;
@property (weak, nonatomic) IBOutlet UIScrollView *likersScrollView;
@property (weak, nonatomic) IBOutlet UIButton *detailPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *slideCellButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *photoBackground;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *recCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *cellMotionButton;
- (void)configureForPost:(FDPost *)post;
+ (CGFloat)cellHeight;
- (IBAction)slideCell;
@end
