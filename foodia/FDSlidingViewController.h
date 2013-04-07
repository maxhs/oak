//
//  FDSlidingViewController.h
//  foodia
//
//  Created by Charles Mezak and Max Haines-Stiles on 7/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "ECSlidingViewController.h"

@interface FDSlidingViewController : ECSlidingViewController
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
-(void)showInstagram:(UIDocumentInteractionController *)ic;
@end
