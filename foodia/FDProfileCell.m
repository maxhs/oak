//
//  FDProfileCell.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/16/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDProfileCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation FDProfileCell
@synthesize mapView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    
    }
    self.mapView.layer.cornerRadius = 5.0f;
    self.mapView.clipsToBounds = YES;
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
