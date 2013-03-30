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
#import "FDAPIClient.h"
#import <QuartzCore/QuartzCore.h>

@implementation FDCommentCell

@synthesize profileImageView, cellPhotoRect;
@synthesize cellComment = _cellComment;
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
    self.cellComment = comment;
    //CGSize bodySize = [comment.body sizeWithFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16] constrainedToSize:CGSizeMake(207, 100000)];
    self.nameLabel.text = comment.user.name;
    self.bodyLabel.text = [NSString stringWithFormat:@"\"%@\"", comment.body];
    CGRect frame = self.bodyLabel.frame;
    frame.size.height = self.bodyLabel.contentSize.height;
    self.bodyLabel.frame = frame;
    [self.timeLabel setText:[Utilities timeIntervalSinceStartDate:comment.date]];
    if (comment.commentId){
        [self.editButton setHidden:NO];
        NSLog(@"comment is not nil");
        [self.editButton setTag:[comment.commentId integerValue]];
        self.editButton.layer.cornerRadius = 14.0f;
        self.editButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
        self.editButton.layer.borderWidth = 1.0f;
    } else {
        [self.editButton setHidden:YES];
    }
}

-(IBAction)deleteComment:(id)sender{
    UIButton *button = (UIButton*) sender;
    [[FDAPIClient sharedClient] deleteCommentWithId:[NSNumber numberWithInt:button.tag] forPostId:self.cellComment.postId success:^(id result) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshPostView" object:nil];
    } failure:^(NSError *error) {
        NSLog(@"error deleting post: %@",error.description);
    }];
}

+ (CGFloat)heightForComment:(FDComment *)comment {
    CGSize bodySize = [comment.body sizeWithFont:[UIFont fontWithName:kAvenirMedium size:16] constrainedToSize:CGSizeMake(207, 100000)];
    return MAX(33 + bodySize.height + 5.f, 60.f);
}

@end
