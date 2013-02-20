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
@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *foursquareButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *instagramButton;
@property (weak, nonatomic) IBOutlet UIScrollView *friendsScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *recScrollView;
@property (weak, nonatomic) FDPost *post;
@property (nonatomic, retain) UIDocumentInteractionController *documentInteractionController;
-(IBAction)toggleFacebook;

@end
