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

- (IBAction)makingTapped {
    [self resetCategoryButtons];
    [self.makingButton setBackgroundColor:[UIColor lightGrayColor]];
    NSLog(@"making tapped");
}

- (IBAction)shoppingTapped {
    [self resetCategoryButtons];
    [self.shoppingButton setBackgroundColor:[UIColor lightGrayColor]];
    NSLog(@"shopping tapped");
}
- (IBAction)drinkingTapped {
    [self resetCategoryButtons];
    [self.drinkingButton setBackgroundColor:[UIColor lightGrayColor]];
    NSLog(@"drinking tapped");
    
}
- (IBAction)eatingTapped {
    [self resetCategoryButtons];
    [self.eatingButton setBackgroundColor:[UIColor lightGrayColor]];
    NSLog(@"eating tapped");
}

-(void) resetCategoryButtons {
    [self.shoppingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.shoppingButton setBackgroundColor:[UIColor clearColor]];
    [self.makingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.makingButton setBackgroundColor:[UIColor clearColor]];
    [self.eatingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.eatingButton setBackgroundColor:[UIColor clearColor]];
    [self.drinkingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.drinkingButton setBackgroundColor:[UIColor clearColor]];
}
@end
