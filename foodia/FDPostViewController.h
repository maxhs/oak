//
//  FDPostViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIScrollView *likersScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *tagsScrollView;
@property (strong, nonatomic) UITextView *addComment;
@property (nonatomic, strong) NSString *postIdentifier;
@property BOOL shouldShowComment;
@property BOOL shouldReframe;
- (IBAction)tapToLike;
- (IBAction)recommend;
- (IBAction)expandImage:(id)sender;
- (void)refresh;
- (IBAction)showPlace:(UIButton*)button;
@end
