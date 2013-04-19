//
//  FDPostViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@interface FDPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIScrollView *likersScrollView;
@property (strong, nonatomic) UITextView *addComment;
@property (nonatomic, strong) NSString *postIdentifier;
@property BOOL shouldShowComment;
- (IBAction)likeButtonTapped;
- (IBAction)recommend;
- (IBAction)expandImage:(id)sender;
- (void)showPostDetails;
- (IBAction)showPlace;
@end
