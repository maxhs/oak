//
//  FDUserCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 10/27/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDUser.h"

@interface FDUserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton       *profileButton;
@property (weak, nonatomic) IBOutlet UILabel        *nameLabel;
@property (strong, nonatomic) IBOutlet UIButton       *actionButton;
@property (nonatomic, retain) NSString              *facebookId;
@property (nonatomic, strong) NSString              *userId;
- (void)setFollowButton;
- (void)setInviteButton;
- (void)setInvitedButton;
- (void)setUnfollowButton;
- (void)configureForUser:(FDUser*)user;
@end
