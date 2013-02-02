//
//  FDShareRecViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/10/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDPost.h"

@interface FDShareRecViewController : UIViewController
@property NSString *recipient;
@property (weak, nonatomic) NSSet *recipients;
@property (weak, nonatomic) NSMutableDictionary *recommendeeList;
@property (weak, nonatomic) FDPost *post;
@property (weak, nonatomic) IBOutlet UIImageView *postImage;
@property (weak, nonatomic) IBOutlet UILabel *foodObject;
@property (weak, nonatomic) IBOutlet UIImageView *posterImage;
-(void)setRecipients:(NSSet *)recipients;
@end
