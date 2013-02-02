//
//  FDCommentCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 8/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDCommentCell.h"
#import "FDComment.h"
#import "FDUser.h"
#import "Utilities.h"
#import "UIImageView+WebCache.h"
#import "FDPostViewController.h"

@implementation FDCommentCell

@synthesize profileImageView, cellPhotoRect;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForComment:(FDComment *)comment {
    //CGSize bodySize = [comment.body sizeWithFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16] constrainedToSize:CGSizeMake(207, 100000)];
    self.nameLabel.text = comment.user.name;
    self.bodyLabel.text = [NSString stringWithFormat:@"\"%@\"", comment.body];
    CGRect frame = self.bodyLabel.frame;
    //frame.size.height = bodySize.height;
    frame.size.height = self.bodyLabel.contentSize.height;
    self.bodyLabel.frame = frame;
    // set user photo
    [profileImageView setImageWithURL:[Utilities profileImageURLForFacebookID:comment.user.facebookId]];
    profileImageView.clipsToBounds = YES;
    self.cellPhotoRect = profileImageView.frame;
    [self.timeLabel setText:[Utilities timeIntervalSinceStartDate:comment.date]];
}

-(void)yupTapped {
    NSLog(@"yup, tapped");
}
+ (CGFloat)heightForComment:(FDComment *)comment {
    CGSize bodySize = [comment.body sizeWithFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16] constrainedToSize:CGSizeMake(207, 100000)];
    return MAX(33 + bodySize.height + 5.f, 60.f);
}

@end
