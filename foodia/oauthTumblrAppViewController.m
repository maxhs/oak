/**
 Copyright 2010 Charles Y. Choi, Yummy Melon Software LLC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */ 

#import "oauthTumblrAppViewController.h"

@implementation oauthTumblrAppViewController

/*@synthesize consumer;
@synthesize accessToken;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.consumer == nil)
        self.consumer = [[OAConsumer alloc] initWithKey:kConsumerKey
                                                 secret:kConsumerSecret];
    
    self.accessToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:kAppProviderName 
                                                                              prefix:kAppPrefix];
    

    
    
    [self authenticateButtonAction];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)authenticateButtonAction {
    NSLog(@"authenticateButtonAction");
    OAMutableURLRequest *request;
    OADataFetcher *fetcher;
    
    NSURL *url = [NSURL URLWithString:@"http://www.tumblr.com/oauth/request_token"];
        
    request = [[OAMutableURLRequest alloc] initWithURL:url
                                               consumer:self.consumer
                                                  token:nil
                                                  realm:nil
                                      signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    

    OARequestParameter *p0 = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"oob"];
    
    NSArray *params = [NSArray arrayWithObject:p0];
    [request setParameters:params];

    fetcher = [[OADataFetcher alloc] init];
    
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
    
}


- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    NSLog(@"requestTokenTicket");
    if (ticket.didSucceed) {
        NSLog(@"Did Succeed");

        OAMutableURLRequest *request;
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        if (self.accessToken != nil) {
            self.accessToken = nil;
        }
        
        self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        
        NSURL *url = [NSURL URLWithString:@"http://www.tumblr.com/oauth/authorize"];
        
        request = [[OAMutableURLRequest alloc] initWithURL:url
                                                   consumer:self.consumer
                                                      token:self.accessToken
                                                      realm:nil
                                          signatureProvider:nil];
        
        
        OARequestParameter *p0 = [[OARequestParameter alloc] initWithName:@"oauth_token"
                                                                    value:self.accessToken.key];
        NSArray *params = [NSArray arrayWithObject:p0];
        [request setParameters:params];
        [request prepare];

        AuthorizeWebViewController *vc;
        vc = [[AuthorizeWebViewController alloc] initWithNibName:@"AuthorizeWebViewController" bundle:nil];
        vc.delegate = self;
        [self presentModalViewController:vc animated:YES];
        [vc.webView loadRequest:request];
        
    }
    else {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];

        NSLog(@"Failed %@",responseBody);
    }

        
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    NSLog(@"ERROR %@", error);
}

#pragma mark AuthorizeWebViewControllerDelegate Methods

- (void)successfulAuthorizationWithPin:(NSString *)pin {
    NSLog(@"successfulAuthorizationWithPin:%@", pin);
    OAMutableURLRequest *request;
    OADataFetcher *fetcher;
    
    NSURL *url = [NSURL URLWithString:@"http://www.tumblr.com/oauth/access_token"];
    
    request = [[OAMutableURLRequest alloc] initWithURL:url
                                               consumer:self.consumer
                                                  token:self.accessToken
                                                  realm:nil
                                      signatureProvider:nil];
    
    
    OARequestParameter *p0 = [[OARequestParameter alloc] initWithName:@"oauth_token"
                                                                value:self.accessToken.key];
    OARequestParameter *p1 = [[OARequestParameter alloc] initWithName:@"oauth_verifier"
                                                                value:pin];
    NSArray *params = [NSArray arrayWithObjects:p0, p1, nil];
    [request setParameters:params];
    
    fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
    
     
    
    
    
}

- (void)failedAuthorization {
    NSLog(@"failedAuthorization");
}



- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    if (ticket.didSucceed) {
        NSLog(@"accessTokenSuccess");
        
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        if (self.accessToken != nil) {
            self.accessToken = nil;
        }
        
        self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        
        [self.accessToken storeInUserDefaultsWithServiceProviderName:kAppProviderName
                                                              prefix:kAppPrefix];
        

    }
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}


- (void)statusRequestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    if (ticket.didSucceed) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseBody);
    }    
    
     
}



- (void)statusRequestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    
}
*/

@end
