//
//  FDPreviewPostView.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/30/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDPreviewPostView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *taglineLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@end
