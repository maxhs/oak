//
//  FDPlacesCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/20/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPlacesCell.h"

@implementation FDPlacesCell

static NSDictionary *placeholderImages;

+ (void)initialize {
    placeholderImages = [NSDictionary dictionaryWithObjectsAndKeys:
                         [UIImage imageNamed:@"detailPlaceholderEating.png"],   @"Eating",
                         [UIImage imageNamed:@"detailPlaceholderDrinking.png"], @"Drinking",
                         [UIImage imageNamed:@"detailPlaceholderMaking.png"],  @"Making",
                         [UIImage imageNamed:@"detailPlaceholderShopping.png"], @"Shopping", nil];
}

+ (UIImage *)placeholderImageForCategory:(NSString *)category {
    return [placeholderImages objectForKey:category];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
