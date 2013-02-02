//
//  FDProfileButton.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/8/12.
//  Copyright (c) 2012 FOODIA, Inc. All rights reserved.
//

@interface FDProfileButton : UIView 
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic,retain) NSString *theUserId;
@property (nonatomic,retain) UIButton *button;
- (id)initWithFrame:(CGRect)frame withUserId:(NSString *)uid;
- (void)setUserId:(NSString *)uid;
- (void)showProfile;

@end
