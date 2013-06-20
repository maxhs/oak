//
//  FDClipView.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/14/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDClipView.h"

@implementation FDClipView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if ([self pointInside:point withEvent:event]) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [_scrollView addGestureRecognizer:tapRecognizer];
        return _scrollView;
	}
	return nil;
}

- (void)tapAction:(UITapGestureRecognizer*)sender{
    CGPoint tapPoint = [sender locationInView:_scrollView];
    int x = tapPoint.x;
    int round = x / 88;
    if (round < 4){
        if (tapPoint.x > 0) {
            [UIView animateWithDuration:.4f animations:^{[_scrollView setContentOffset:CGPointMake(88*round,0)];}];
        } else {
            [UIView animateWithDuration:.4f animations:^{[_scrollView setContentOffset:CGPointMake(-88*round,0)];}];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HideKeyboard" object:nil];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
