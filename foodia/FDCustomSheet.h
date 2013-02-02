//
//  FDCustomSheet.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/20/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDPost.h"

@interface FDCustomSheet : UIActionSheet
@property (weak,nonatomic) NSString *postId;
@property (weak,nonatomic) NSString *foodiaObject;
@property (weak,nonatomic) FDPost *post;

@end
