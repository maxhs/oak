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

@implementation FDUserCell
@synthesize facebookId, button, currentButton, imageFrame;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)buttonPressed
{
    if([currentButton isEqualToString:@"Invite"]) {
        [self inviteUser:self.facebookId];
    } else if([currentButton isEqualToString:@"Follow"]) {
        [self setUnfollowButton];
        (void)[[FDAPIClient sharedClient] followUser:self.facebookId];
    } else if([currentButton isEqualToString:@"Unfollow"]) {
        [self setFollowButton];
        (void)[[FDAPIClient sharedClient] unfollowUser:self.facebookId];
    }
    
}
 
- (void)setInviteButton
{
    [button setHidden:false];
    [button setTitle:@"Invite" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor redColor]];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15]];
    currentButton = @"Invite";
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    button.userInteractionEnabled = YES;
}

- (void)setInvitedButton
{
    [button setHidden:false];
    [button setTitle:@"Invited" forState:UIControlStateNormal];
    [button setEnabled:NO];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
    currentButton = @"Invited";
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.userInteractionEnabled = NO;
}

- (void)setFollowButton
{
    [button setHidden:false];
    [button setTitle:@"Follow" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor whiteColor]];
    [button.layer setBorderColor:[UIColor redColor].CGColor];
    [button.layer setBorderWidth:1.0];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15]];
    currentButton = @"Follow";
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)setUnfollowButton
{
    [button setHidden:false];
    [button setTitle:@"Unfollow" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:15]];
    currentButton = @"Unfollow";
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)setFacebookId:(NSString *)newFacebookId
{
    facebookId = newFacebookId;
    [self.profileImageView setImageWithURL:[Utilities profileImageURLForFacebookID:newFacebookId]];
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.cornerRadius = 5.0;
    self.profileImageView.layer.shouldRasterize = YES;
    self.profileImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    imageFrame = self.profileImageView.frame;
    button.tag = [facebookId integerValue];
    [button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
}

-(void)inviteUser:(NSString *)who {
    [self setInvitedButton];
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObjects:@"publish_actions",nil] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (!error) {
                // If permissions granted, publish the story
                if ([FBSession.activeSession.permissions
                     indexOfObject:@"publish_actions"] != NSNotFound) {
                    NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:who forKey:@"fbid"];
                    //[[NSUserDefaults standardUserDefaults] setObject:session.accessToken forKey:@"FacebookAccessToken"];
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
        NSDictionary *inviteRecipient = [NSDictionary dictionaryWithObject:who forKey:@"fbid"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"SendInvite"
         object:inviteRecipient];
    }
}

@end
