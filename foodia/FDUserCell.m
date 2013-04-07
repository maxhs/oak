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
    NSLog(@"button pressed for this user: %i",button.tag);
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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6) {
        [self.actionButton.titleLabel setFont:[UIFont fontWithName:kAvenirDemiBold size:15]];
    } else {
        [self.actionButton.titleLabel setFont:[UIFont fontWithName:kFuturaMedium size:15]];
    }
    if (user.fbid){
        [self.profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:user.fbid] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            if (image) {
                [self.profileButton.imageView setImage:image];
                [UIView animateWithDuration:.25 animations:^{
                    [self.profileButton setAlpha:1.0];
                }];
            }
        }];
        self.profileButton.titleLabel.text = [NSString stringWithFormat:@"%@",user.fbid];
        self.profileButton.titleLabel.hidden = YES;
        
    } else {
        if (user.facebookId.length){
            [self.profileButton setImageWithURL:[Utilities profileImageURLForFacebookID:user.facebookId] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (image) {
                    [self.profileButton.imageView setImage:image];
                    [UIView animateWithDuration:.25 animations:^{
                        [self.profileButton setAlpha:1.0];
                    }];
                }
            }];
        } else {
            
            [[FDAPIClient sharedClient] getProfilePic:user.userId success:^(NSURL *url) {
                [self.profileButton setImageWithURL:url forState:UIControlStateNormal];
                NSLog(@"should be setting avatar url for user: %@",url);
            } failure:^(NSError *error) {
                
            }];
            self.profileButton.titleLabel.hidden = YES;
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
    if (user.fbid){
        self.facebookId = user.fbid;
        [self.actionButton addTarget:self action:@selector(inviteUser) forControlEvents:UIControlEventTouchUpInside];
        [self setInviteButton];
    } else {
        [self.actionButton setTag:[user.userId integerValue]];
            [self.actionButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6) {
        [self.nameLabel setFont:[UIFont fontWithName:kFuturaMedium size:16]];
    }
}

-(void)inviteUser {
    [self setInvitedButton];
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (!error) {
                // If permissions granted, publish the story
                if ([FBSession.activeSession.permissions
                     indexOfObject:@"publish_actions"] != NSNotFound) {
                    NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:self.facebookId forKey:@"fbid"];
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"SendInvite"
                     object:inviteRecipient];
                    NSLog(@"sending invite from userCell");
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we can't send invites through Facebook without your permission." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                }
            }
        }];
    } else if ([FBSession.activeSession.permissions
                indexOfObject:@"publish_actions"] != NSNotFound) {
        // If permissions present, publish the story
        NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:self.facebookId forKey:@"fbid"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"SendInvite"
         object:inviteRecipient];
    }
}

@end
