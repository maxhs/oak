//
//  FDWebViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 2/4/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

@interface FDWebViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURL *url;
@end
