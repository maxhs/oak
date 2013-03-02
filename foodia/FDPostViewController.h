//
//  FDPostViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIScrollView *likersScrollView;
@property (weak, nonatomic) IBOutlet UITextView *foodiaObjectTextView;
@property (weak, nonatomic) UITextView *addComment;
@property (nonatomic, strong) NSString *postIdentifier;
- (IBAction)likeButtonTapped:(id)sender;
- (IBAction)recommend;
- (IBAction)expandImage:(id)sender;
- (void)showPostDetails;
- (IBAction)showPlace;
@end
