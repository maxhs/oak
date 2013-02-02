//
//  FDNewPostViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 11/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPost.h"

@interface FDNewPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButtonItem;
@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *foursquareButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *instagramButton;
@property (strong, nonatomic) FDPost *post;
@property (nonatomic, retain) UIDocumentInteractionController *documentInteractionController;
-(IBAction)toggleFacebook;

@end
