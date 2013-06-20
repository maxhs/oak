//
//  FDPostCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 7/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostCell.h"
#import "FDPost.h"
#import "FDUser.h"
#import "FDAPIClient.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"
#import <QuartzCore/QuartzCore.h>
#import "FDPostTableViewController.h"
#import "FDProfileViewController.h"
#import <MessageUI/MessageUI.h>
#import "FDFeedNavigationViewController.h"
#import "FDPostTableViewController.h"

@interface FDPostCell () <UIScrollViewDelegate>

@property (nonatomic,strong) AFJSONRequestOperation *postRequestOperation;
@property (nonatomic,strong) NSString *postId;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) FDPost *post;
@end

@implementation FDPostCell

@synthesize socialLabel, userId, post;

static NSDictionary *placeholderImages;

+ (void)initialize {
    placeholderImages = [NSDictionary dictionaryWithObjectsAndKeys:
                      [UIImage imageNamed:@"feedPlaceholderEating.png"],   @"Eating",
                      [UIImage imageNamed:@"feedPlaceholderDrinking.png"], @"Drinking",
                      [UIImage imageNamed:@"feedPlaceholderMaking.png"],  @"Making",
                      [UIImage imageNamed:@"feedPlaceholderShopping.png"], @"Shopping", nil];
}

+ (UIImage *)placeholderImageForCategory:(NSString *)category {
    return [placeholderImages objectForKey:category];
}

+ (CGFloat)cellHeight {
    return 155;
}

-(void)showPost {
    [self.scrollView setContentSize:CGSizeMake(542,115)];
    self.scrollView.delegate = self;
    [self.slideCellButton setHidden:YES];
    self.postId = self.post.identifier;
    self.userId = self.post.user.facebookId;
    // set up the user image
    /*if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:self.post.user.userId]) {
        [self.posterButton setImage:[[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:self.post.user.userId] forState:UIControlStateNormal];
    } else */if (self.post.user.facebookId.length && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookAccessToken]){
        [self.posterButton.imageView setImageWithURL:[Utilities profileImageURLForFacebookID:self.post.user.facebookId] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [self.posterButton setImage:image forState:UIControlStateNormal];
        }];
    } else {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/foodia-uploads/user_%@_thumb.jpg",self.post.user.userId]];
        [self.posterButton.imageView setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [self.posterButton setImage:image forState:UIControlStateNormal];
        }];
    }
    
    self.posterButton.imageView.layer.cornerRadius = 22.0f;
    [self.posterButton.imageView setBackgroundColor:[UIColor clearColor]];
    [self.posterButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    self.posterButton.imageView.layer.shouldRasterize = YES;
    self.posterButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // show the time stamp
    if([post.postedAt timeIntervalSinceNow] > 0) {
        self.timeLabel.text = @"0s";
    } else {
        self.timeLabel.text = [Utilities timeIntervalSinceStartDate:self.post.postedAt];
    }
    // show the photo if present
    if (!self.post.hasPhoto) {
        [self.photoImageView setImage:[FDPostCell placeholderImageForCategory:self.post.category]];
        [UIView animateWithDuration:.25 animations:^{
            [self.photoImageView setAlpha:1.0];
            [self.posterButton setAlpha:1.0];
            [self.photoBackground setAlpha:1.0];
        }];
    } else {
        [self.photoImageView setImageWithURL:self.post.feedImageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            if (image && !error) {
                self.photoImageView.image = image;
                [UIView animateWithDuration:.25 animations:^{
                    [self.photoImageView setAlpha:1.0];
                    [self.posterButton setAlpha:1.0];
                    [self.photoBackground setAlpha:1.0];
                }];
            } else {
                NSLog(@"error drawing feed photo: %@",error.description);
            }
        }];
    }
    
    // show the like count, and set the like button's image to indicate whether current user likes
    self.likeCountLabel.text = [NSString stringWithFormat:@"%@", self.post.likeCount];
    self.recCountLabel.text = [NSString stringWithFormat:@"%@", self.post.recCount];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%@", self.post.commentCount];
    
    if ([self.post.locationName isEqualToString:@""]){
        [self.locationButton setHidden:YES];
    } else {
        [self.locationButton setTitle:self.post.locationName forState:UIControlStateNormal];
    }
    
    UIImage *likeButtonImage;
    if ([post isLikedByUser]) {
        likeButtonImage = [UIImage imageNamed:@"light_smile"];
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"likeBubbleSelected"] forState:UIControlStateNormal];
    } else {
        likeButtonImage = [UIImage imageNamed:@"dark_smile"];
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"recBubble"] forState:UIControlStateNormal];
    }
    self.likeButton.layer.shouldRasterize = YES;
    self.likeButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // show the social string for the post
    self.socialLabel.text = self.post.socialString;
    
    [self bringSubviewToFront:self.detailPhotoButton];
}

// here we configure the cell to display a given post
- (void)configureForPost:(FDPost *)thePost {
    self.post = thePost;
    [self showPost];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        NSDictionary *userInfo;
        if (self.post) {
            userInfo = [NSDictionary dictionaryWithObject:self.post.identifier forKey:@"identifier"];
        }
        if (scrollView.contentOffset.x > 270) {
            if (userInfo)[[NSNotificationCenter defaultCenter] postNotificationName:@"CellOpened" object:nil userInfo:userInfo];
            [self.slideCellButton setHidden:NO];
        } else {
            if (userInfo)[[NSNotificationCenter defaultCenter] postNotificationName:@"CellClosed" object:nil userInfo:userInfo];
            [self.slideCellButton setHidden:YES];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        self.cellMotionButton.transform = CGAffineTransformMakeRotation((180 * scrollView.contentOffset.x/271)*M_PI/180);
        if (scrollView.contentOffset.x > 270) {
            [self.slideCellButton setHidden:NO];
        } else {
            [self.slideCellButton setHidden:YES];
        }
    }
}

- (IBAction)slideCell {
    NSDictionary *userInfo;
    if (self.post){
        userInfo = [NSDictionary dictionaryWithObject:self.post.identifier forKey:@"identifier"];
    }
    if (self.scrollView.contentOffset.x < 270 ){
        [self.scrollView setContentOffset:CGPointMake(271,0) animated:YES];
        [self.slideCellButton setHidden:NO];
        if (userInfo) [[NSNotificationCenter defaultCenter] postNotificationName:@"CellOpened" object:nil userInfo:userInfo];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        if (userInfo) [[NSNotificationCenter defaultCenter] postNotificationName:@"CellClosed" object:nil userInfo:userInfo];
        [self.slideCellButton setHidden:YES];
    }
}

@end
