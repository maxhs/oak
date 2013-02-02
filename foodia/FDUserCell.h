//
//  FDUserCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 10/27/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDUserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel        *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton       *button;
@property (nonatomic, retain) NSString              *facebookId;
@property (nonatomic, retain) NSString              *currentButton;
@property CGRect imageFrame;
- (void)setFacebookId:(NSString *)newFacebookId;
- (void)setFollowButton;
- (void)setInviteButton;
- (void)setInvitedButton;
- (void)setUnfollowButton;
@end
