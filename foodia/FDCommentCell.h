//
//  FDCommentCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 8/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@class FDComment;

@interface FDCommentCell : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UITextView *bodyLabel;
@property (nonatomic, retain) IBOutlet UILabel *timeLabel;
@property (nonatomic, retain) FDComment *cellComment;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property CGRect cellPhotoRect;
+ (CGFloat)heightForComment:(FDComment *)comment;
- (void)configureForComment:(FDComment *)comment;
@end
