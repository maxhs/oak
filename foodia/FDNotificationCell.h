//
//  FDNotificationCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 9/6/12.
//  Copyright (c) 2012 FOODIA, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDNotification.h"
@interface FDNotificationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

- (void)configureForNotification:(FDNotification *)notification;

+ (CGFloat)cellHeight;
@end
