//
//  FDPostGridCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 9/2/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPostGridCell.h"
#import "FDPost.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"
#import <QuartzCore/QuartzCore.h>

@interface FDPostGridCell ()

@property (strong, retain) FDPost *post;
@property (strong, retain) FDPost *post1;
@property (strong, retain) FDPost *post2;


@end


@implementation FDPostGridCell

@synthesize post, post1, post2;

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
    return 80;
}



// here we configure the cell to display a given post
- (void)configureForPost:(NSMutableArray *)cellPosts {
    // show the photo if present
    if (cellPosts != nil) {
        post = [cellPosts objectAtIndex:0];
        post1 = [cellPosts objectAtIndex:1];
        post2 = [cellPosts objectAtIndex:2];
        [self.photoImageView setImageWithURL:post.featuredImageURL];
        [self.photoImageView1 setImageWithURL:post1.featuredImageURL];
        [self.photoImageView2 setImageWithURL:post2.featuredImageURL];
    } else {
        post = [cellPosts objectAtIndex:0];
        [self.photoImageView setImage:[FDPostGridCell placeholderImageForCategory:post.category]];
    }
}

@end
