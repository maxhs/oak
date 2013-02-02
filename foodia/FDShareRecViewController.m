//
//  FDShareRecViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/10/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDShareRecViewController.h"
#import "FDUser.h"
#import "FDAPIClient.h"
#import "Utilities.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>

NSString *const kPlaceholderRecMessage = @"Tap here to write a custom recommendation for your friend(s).";

@interface FDShareRecViewController () <UITextViewDelegate, UIAlertViewDelegate>
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)postButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *postMessageTextView;
@property (strong, nonatomic) NSMutableDictionary *postParams;
@end

@implementation FDShareRecViewController

@synthesize postParams = _postParams;
@synthesize recipients, recommendeeList;
static NSDictionary *placeholderImages;

+ (void)initialize {
    placeholderImages = [NSDictionary dictionaryWithObjectsAndKeys:
                         [UIImage imageNamed:@"feedPlaceholderEating.png"],   @"Eating",
                         [UIImage imageNamed:@"feedPlaceholderDrinking.png"], @"Drinking",
                         [UIImage imageNamed:@"feedPlaceholderMaking.png"],  @"Making",
                         [UIImage imageNamed:@"feedPlaceholderShopping.png"], @"Shopping", nil];
}

+ (UIImage *)placeholderImageForCategory:(NSString *)category {
    return [placeholderImages objectForKey:category];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.postParams =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:
         @"I just recommended something to you on FOODIA!", @"description",
         nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TestFlight passCheckpoint:@"Sharing via Facebook"];
    // Do any additional setup after loading the view from its nib.
    NSLog(@"self.post.category: %@",self.post.category);
    if (self.post.hasPhoto) {
        [self.postImage setImageWithURL:self.post.feedImageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            if (image) {
                self.postImage.image = image;
                CGPathRef path = [UIBezierPath bezierPathWithRect:self.postImage.bounds].CGPath;
                [self.postImage.layer setShadowPath:path];
                self.postImage.layer.shouldRasterize = YES;

                self.postImage.layer.rasterizationScale = [UIScreen mainScreen].scale;
                self.postImage.layer.shadowColor = [UIColor lightGrayColor].CGColor;
                self.postImage.layer.shadowOffset = CGSizeMake(0, 1);
                self.postImage.layer.shadowOpacity = 1;
                self.postImage.layer.shadowRadius = 2.0;
                self.postImage.clipsToBounds = NO;
            }
        }];
    } else {
        NSLog(@"trying to reset postImage with placeholder");
        [self.postImage setImage:[FDShareRecViewController placeholderImageForCategory:self.post.category]];
    }
    self.foodObject.text = self.post.foodiaObject;
    self.posterImage.clipsToBounds = YES;
    self.posterImage.layer.cornerRadius = 5.0f;
    [self.posterImage setImageWithURL:[Utilities profileImageURLForFacebookID:self.post.user.facebookId]];
    // Show placeholder text
    [self resetPostMessage];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPressed:(id)sender {
    [[self presentingViewController]
     dismissModalViewControllerAnimated:YES];
}

- (IBAction)postButtonPressed:(id)sender {
    // Hide keyboard if showing when button clicked
    if ([self.postMessageTextView isFirstResponder]) {
        [self.postMessageTextView resignFirstResponder];
    }
    
    // Add user message parameter if user filled it in
    if (![self.postMessageTextView.text
          isEqualToString:kPlaceholderRecMessage] &&
        ![self.postMessageTextView.text isEqualToString:@""]) {
        [self.postParams setObject:self.postMessageTextView.text
                            forKey:@"message"];
    }
    
    if (self.post.foodiaObject != nil) {
        [self.postParams setObject:self.post.foodiaObject forKey:@"name"];
    } else {
        [self.postParams setObject:@"Download FOODIA!" forKey:@"name"];
    }
    
    if (self.post.identifier) {
        [self.postParams setObject:[NSString stringWithFormat:@"http://posts.foodia.com/p/%@",self.post.identifier] forKey:@"link"];
    } else {
        [self.postParams setObject:@"http://posts.foodia.com/" forKey:@"link"];
    }
    
    if (self.post.hasDetailPhoto){
        [self.postParams setObject:self.post.detailImageUrlString forKey:@"picture"];
    } else {
        [self.postParams setObject:@"http://foodia.com/images/FOODIA_red_512x512_bg.png" forKey:@"picture"];
    }

    [FBSettings setLoggingBehavior:[NSSet setWithObjects:FBLoggingBehaviorFBRequests, FBLoggingBehaviorFBURLConnections, nil]];
    
    if (self.recipients != nil) {
        for (FDUser *recommendee in self.recipients){
            [FBRequestConnection
             startWithGraphPath:[NSString stringWithFormat:@"%@/feed", recommendee.facebookId]
             parameters:self.postParams
             HTTPMethod:@"POST"
             completionHandler:^(FBRequestConnection *connection,
                                 id result,
                                 NSError *error) {
                 if (error) {
                     NSLog(@"recommendation failed! %@", error.description);
                     [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Facebook won't allow us to post your recommendation. Shucks!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                 } else {
                     [[FDAPIClient sharedClient] recommendPost:self.post toRecommendees:self.recipients withMessage:self.postMessageTextView.text success:^(FDPost *post) {
                         if (post) {
                             // Show a thanks alertview
                             [[[UIAlertView alloc] initWithTitle:@"Good going!"
                                                         message:@"Recommendations make the world turn. Why not make another?"
                                                        delegate:self
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil]
                              show];
                            
                         }
                     } failure:^(NSError *error) {
                         NSLog(@"recommendation failed! %@", error.description);
                         [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't reach Facebook with your recommendation. We'll keep trying." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                     }];
                     
                 }
                 
             }];
        }
    }
    //return to recommend view controller
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

/*-(void) alertViewCancel:(UIAlertView *)alertView {
    NSLog(@"dismissed");
}*/

- (void)viewDidUnload {
    [self setPostMessageTextView:nil];
    //[self setPostImageView:nil];
    [self setRecipients:nil];
    [super viewDidUnload];
}

- (void)resetPostMessage
{
    self.postMessageTextView.text = kPlaceholderRecMessage;
    self.postMessageTextView.textColor = [UIColor lightGrayColor];
    self.postMessageTextView.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderRecMessage]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        [self resetPostMessage];
    }
}

/*
 * A simple way to dismiss the message text view:
 * whenever the user clicks outside the view.
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.postMessageTextView isFirstResponder] &&
        (self.postMessageTextView != touch.view))
    {
        [self.postMessageTextView resignFirstResponder];
    }
}

@end
