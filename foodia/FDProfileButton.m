//
//  FDProfileButton.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/8/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDProfileButton.h"
#import "Utilities.h"
#import "UIImageView+WebCache.h"
#import "UIButton+WebCache.h"
#import "SDImageCache.h"
#import <QuartzCore/QuartzCore.h>
#import "FDProfileViewController.h"

@implementation FDProfileButton

@synthesize button, imageView, theUserId;

- (id)initWithFrame:(CGRect)frame withUserId:(NSString *)uid
{
    self = [super initWithFrame:frame];
        if (self.imageView == nil) {
            self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
            [self addSubview:self.imageView];
            self.imageView.layer.cornerRadius = 5.0;
            self.imageView.clipsToBounds = YES;
            
            self.button = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.button addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
            self.button.frame = self.bounds;
            [self addSubview:self.button];
            self.button.backgroundColor = [UIColor clearColor];
        }
        self.theUserId = uid;
        NSString *imagePath = [Utilities profileImagePathForUserId:uid];
        [self.imageView setImageWithURL:[NSURL URLWithString:imagePath] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            self.imageView.image = image;
        }];
    return self;
}

- (void)setUserId:(NSString *)uid {
    if (self.imageView == nil) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];
        self.imageView.layer.cornerRadius = 5.0;
        self.imageView.clipsToBounds = YES;
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
        self.button.frame = self.bounds;
        [self addSubview:self.button];
        self.button.backgroundColor = [UIColor clearColor];
        
    }
    self.theUserId = uid;
    NSString *imagePath = [Utilities profileImagePathForUserId:uid];
    [self.imageView setImageWithURL:[NSURL URLWithString:imagePath] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        self.imageView.image = image;
    }];
}

- (void)showProfile {
    if (self.theUserId == nil) return;
    [((FDAppDelegate *)[UIApplication sharedApplication].delegate) showUserProfile:self.theUserId];

}

@end
