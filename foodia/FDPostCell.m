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
    // set up the poster button
    [self.posterButton setImageWithURL:[Utilities profileImageURLForFacebookID:self.post.user.facebookId] forState:UIControlStateNormal];
    self.posterButton.imageView.layer.cornerRadius = 22.0f;
    //self.posterButton.clipsToBounds = YES;
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
                self.photoImageView.clipsToBounds = NO;
            } else {
                NSLog(@"error drawing feed photo: %@",error.description);
            }
        }];
    }
    
    // show the like count, and set the like button's image to indicate whether current user likes
    self.likeCountLabel.text = [NSString stringWithFormat:@"%@", self.post.likeCount];
    self.recCountLabel.text = [NSString stringWithFormat:@"%d", [self.post.recommendedTo count]];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%i", self.post.comments.count];
    
    self.locationButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
    self.locationButton.layer.borderWidth = 1.0f;
    self.locationButton.backgroundColor = [UIColor whiteColor];
    self.locationButton.layer.cornerRadius = 17.0f;
    self.locationButton.layer.shouldRasterize = YES;
    self.locationButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    if ([self.post.locationName isEqualToString:@""]){
        [self.locationButton setHidden:YES];
    } else {
        [self.locationButton setTitle:self.post.locationName forState:UIControlStateNormal];
    }
    
    UIImage *likeButtonImage;
    if ([post isLikedByUser]) {
        likeButtonImage = [UIImage imageNamed:@"light_smile"];
        [self.likeButton setBackgroundColor:kColorLightBlack];
        self.likeButton.layer.borderColor = kColorLightBlack.CGColor;
    } else {
        likeButtonImage = [UIImage imageNamed:@"dark_smile"];
        [self.likeButton setBackgroundColor:[UIColor whiteColor]];
        self.likeButton.layer.borderColor = [UIColor colorWithWhite:.1 alpha:.1].CGColor;
    }
    
    [self.likeButton setImage:likeButtonImage forState:UIControlStateNormal];
    self.likeButton.layer.borderWidth = 1.0f;
    
    self.likeButton.layer.cornerRadius = 17.0f;
    self.likeButton.layer.shouldRasterize = YES;
    self.likeButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // show the social string for the post
    self.socialLabel.text = self.post.socialString;
}

// here we configure the cell to display a given post
- (void)configureForPost:(FDPost *)thePost {
    self.post = thePost;
    [self showPost];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x > 270) {
        [self.slideCellButton setHidden:NO];
    } else {
        [self.slideCellButton setHidden:YES];
    }
}

- (IBAction)slideCell {
    
    if (self.scrollView.contentOffset.x < 270 ){
        [self.scrollView setContentOffset:CGPointMake(271,0) animated:YES];
        [self.slideCellButton setHidden:NO];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        [self.slideCellButton setHidden:YES];
    }
}

@end
