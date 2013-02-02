//
//  FDShareViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/7/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDShareViewController : UIViewController
@property NSString *recipient;
@property (weak, nonatomic) NSMutableArray *recipients;
-(void)setRecipients:(NSMutableArray *)recipients;
@end
