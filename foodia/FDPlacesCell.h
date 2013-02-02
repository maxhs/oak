//
//  FDPlacesCell.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/20/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

@interface FDPlacesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (weak, nonatomic) IBOutlet UILabel *placeAddress;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *statusHours;
@property (weak, nonatomic) IBOutlet UILabel *likes;
@property (weak, nonatomic) IBOutlet UIImageView *postImage;

@end
