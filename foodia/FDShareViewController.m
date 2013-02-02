//
//  FDShareViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/7/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDShareViewController.h"
#import "FDUser.h"
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>

NSString *const kPlaceholderPostMessage = @"Tap here to write a custom message for your friend or friends' Facebook wall(s).";

@interface FDShareViewController () <UITextViewDelegate, UIAlertViewDelegate>
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)postButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *postMessageTextView;
@property (weak, nonatomic) UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;

@property (strong, nonatomic) NSMutableDictionary *postParams;

@end

@implementation FDShareViewController

@synthesize postParams = _postParams;
@synthesize postImageView;
@synthesize recipient;
@synthesize recipients;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.postParams =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:
        @"Download FOODIA", @"name",
        @"http://foodia.com/images/FOODIA_red_512x512_bg.png",@"picture",
        @"Spend less time with your phone and more time with your food.", @"description",
        @"http://posts.foodia.com/", @"link",
        nil];
        self.postMessageTextView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        self.postMessageTextView.layer.borderWidth = 5.0f;
        self.postMessageTextView.layer.cornerRadius = 5.0f;
        self.postButton.enabled = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.postImageView setImage:[UIImage imageNamed:@"Transparent_Crab_128x128.png"]];
    // Show placeholder text
    [self resetPostMessage];
    
    // Set the preview image
    //self.postImageView.image = [UIImage imageNamed:@"iossdk_logo.png"];
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
    self.postButton.enabled = NO;
    // Hide keyboard if showing when button clicked
    if ([self.postMessageTextView isFirstResponder]) {
        [self.postMessageTextView resignFirstResponder];
    }
    
    // Add user message parameter if user filled it in
    if (![self.postMessageTextView.text
          isEqualToString:kPlaceholderPostMessage] &&
        ![self.postMessageTextView.text isEqualToString:@""]) {
        [self.postParams setObject:self.postMessageTextView.text
                            forKey:@"message"];
    }
    
    [FBSettings setLoggingBehavior:[NSSet setWithObjects:FBLoggingBehaviorFBRequests, FBLoggingBehaviorFBURLConnections, nil]];
    
    [FBRequestConnection
     startWithGraphPath:[NSString stringWithFormat:@"%@/feed", self.recipient]
     parameters:self.postParams
     HTTPMethod:@"POST"
     completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {
         
         /*if (error) {
             alertText = [NSString stringWithFormat:
                          @"error: domain = %@, code = %d",
                          error.domain, error.code];
         } else {
             
         }*/
         // Show the result in an alert
         [[[UIAlertView alloc] initWithTitle:@"Good going."
                                     message:@"Thanks for inviting your friend to join. Why not invite a few more?"
                                    delegate:self
                           cancelButtonTitle:@"Okay."
                           otherButtonTitles:nil]
          show];
     }];
    //}
}

- (void)viewDidUnload {
    [self setPostMessageTextView:nil];
    [self setPostImageView:nil];
    [self setRecipients:nil];
    [super viewDidUnload];
}

- (void)resetPostMessage
{
    self.postMessageTextView.text = kPlaceholderPostMessage;
    self.postMessageTextView.textColor = [UIColor lightGrayColor];
    self.postMessageTextView.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderPostMessage]) {
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

- (void) alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[self presentingViewController]
     dismissModalViewControllerAnimated:YES];
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
