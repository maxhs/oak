//
//  FDPhotoLibraryCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 4/28/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPhotoLibraryCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@implementation FDPhotoLibraryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)configureForAssets:(NSMutableArray *)photoAssets {
    [self.button1 setImage:[UIImage imageWithCGImage:[(ALAsset*)[photoAssets objectAtIndex:0] thumbnail]] forState:UIControlStateNormal];
    [self.button2 setImage:[UIImage imageWithCGImage:[(ALAsset*)[photoAssets objectAtIndex:1] thumbnail]] forState:UIControlStateNormal];
    [self.button3 setImage:[UIImage imageWithCGImage:[(ALAsset*)[photoAssets objectAtIndex:2] thumbnail]] forState:UIControlStateNormal];
    [self.button4 setImage:[UIImage imageWithCGImage:[(ALAsset*)[photoAssets objectAtIndex:3] thumbnail]] forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
