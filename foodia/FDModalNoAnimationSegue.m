//
//  FDModalNoAnimationSegue.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//
//

#import "FDModalNoAnimationSegue.h"

@implementation FDModalNoAnimationSegue
- (void)perform {
    [self.sourceViewController presentModalViewController:self.destinationViewController animated:NO];
}
@end
