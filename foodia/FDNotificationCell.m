//
//  FDNotificationCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/6/12.
//  Copyright (c) 2012 FOODIA, Inc. All rights reserved.
//

#import "FDNotificationCell.h"
#import "Utilities.h"
#import "Facebook.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"
#import "FDAPIClient.h"

@implementation FDNotificationCell

@synthesize messageLabel,timeLabel,profileButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


+ (CGFloat)cellHeight {
    return 60;
}

// here we configure the cell to display a given post
- (void)configureForNotification:(FDNotification *)notification {
    [messageLabel setText:notification.message];
    
    // show the time stamp
    if([notification.postedAt timeIntervalSinceNow] > 0) {
        self.timeLabel.text = @"0s";
    } else {
        self.timeLabel.text = [Utilities timeIntervalSinceStartDate:notification.postedAt];
    }
    self.profileButton.tag = [notification.fromUserId integerValue];
    // set user photo
    if (notification.fromUserFbid.length) {
        [self.profileImageView setImageWithURL:[Utilities profileImageURLForFacebookID:notification.fromUserFbid]];
    } else {
        [[FDAPIClient sharedClient] getProfilePic:notification.fromUserId success:^(id result) {
            [self.profileImageView setImageWithURL:result];
        } failure:^(NSError *error) {}];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
