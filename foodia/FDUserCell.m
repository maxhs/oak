//
//  FDUserCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 10/27/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDUserCell.h"
#import "FDAPIClient.h"
#import "FDCache.h"
#import "FDSocialViewController.h"
#import "Facebook.h"
#import "Utilities.h"
#import "UIButton+WebCache.h"

@implementation FDUserCell
@synthesize facebookId, actionButton;
@synthesize userId = _userId;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)buttonPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    if ([button.titleLabel.text isEqualToString:@"Follow"]) {
        [self setUnfollowButton];
        [[FDAPIClient sharedClient] followUser:[NSString stringWithFormat:@"%i",button.tag]];
    } else if([button.titleLabel.text isEqualToString:@"Following"]) {
        [self setFollowButton];
        [[FDAPIClient sharedClient] unfollowUser:[NSString stringWithFormat:@"%i",button.tag]];
    }
}
 
- (void)setInviteButton
{
    [self.actionButton setTitle:@"Invite" forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:kColorLightBlack];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.actionButton.layer.shouldRasterize = YES;
    self.actionButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.actionButton.userInteractionEnabled = YES;
}

- (void)setInvitedButton
{
    [self.actionButton setTitle:@"Invited" forState:UIControlStateNormal];
    [self.actionButton setEnabled:NO];
    [self.actionButton setBackgroundColor:[UIColor clearColor]];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.actionButton.layer.shouldRasterize = YES;
    self.actionButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.actionButton.userInteractionEnabled = NO;
}

- (void)setFollowButton
{
    [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:[UIColor whiteColor]];
    [self.actionButton.layer setBorderColor:kColorLightBlack.CGColor];
    [self.actionButton.layer setBorderWidth:1.0];
    [self.actionButton setTitleColor:kColorLightBlack forState:UIControlStateNormal];
    self.actionButton.layer.shouldRasterize = YES;
    self.actionButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)setUnfollowButton
{
    [self.actionButton setTitle:@"Following" forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:[UIColor whiteColor]];
    [self.actionButton.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.actionButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.actionButton.layer.shouldRasterize = YES;
    self.actionButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)configureForUser:(FDUser *)user
{
    
    self.actionButton.layer.cornerRadius = 17.0;
    self.actionButton.layer.shouldRasterize = YES;
    self.actionButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.actionButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
    if (user.fbid){
        [self.profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:user.fbid] forState:UIControlStateNormal];
        [UIView animateWithDuration:.25 animations:^{
            [self.profileButton setAlpha:1.0];
        }];
    } else {
        if (user.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
            [self.profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:user.facebookId] forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [self.profileButton setAlpha:1.0];
            }];
        } else {
            //set from Amazon. risky...
            [self.profileButton setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",user.userId]] forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [self.profileButton setAlpha:1.0];
            }];
        }
    }
    [self.nameLabel setText:user.name];
    self.profileButton.imageView.layer.cornerRadius = 20.0;
    [self.profileButton.imageView setBackgroundColor:[UIColor clearColor]];
    [self.profileButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.profileButton.imageView.layer.shouldRasterize = YES;
    self.profileButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    if (user.fbid.length){
        self.facebookId = user.fbid;
        [self setInviteButton];
    } else {
        [self.actionButton setTag:[user.userId integerValue]];
        [self.actionButton removeTarget:self action:@selector(inviteUser) forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

@end
