//
//  FDTumblrAPIClient.m
//  foodia
//
//  Created by Charles Mezak and Max Haines-Stiles on 7/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDTumblrAPIClient.h"
#import "KeychainItemWrapper.h"

#define BASE_URL @"http://api.tumblr.com/api/"
#define SEND_POST_PATH @"write"
#define VALIDATE_PATH @"authenticate"
#define KEYCHAIN_IDENTIFIER @"com.foodia.app.tumblr"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);

@implementation FDTumblrAPIClient

@synthesize userEmail, userPassword;

static FDTumblrAPIClient *singleton;

+ (void)initialize {
    singleton = [[FDTumblrAPIClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
}

+ (FDTumblrAPIClient *)sharedClient {
    return singleton;
}

- (void)loadCredentialsFromKeychain {
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_IDENTIFIER accessGroup:nil];
    id kUserEmailKey = (__bridge id)kSecAttrAccessGroup;
    id kUserPasswordKey = (__bridge id)kSecValueData;
    singleton.userEmail = [wrapper objectForKey:kUserEmailKey];
    singleton.userPassword = [wrapper objectForKey:kUserPasswordKey];
}

- (void)storeCredentialsInKeychain {
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_IDENTIFIER accessGroup:nil];
    id kUserEmailKey = (__bridge id)kSecAttrAccessGroup;
    id kUserPasswordKey = (__bridge id)kSecValueData;
    [wrapper setObject:self.userEmail forKey:kUserEmailKey];
    [wrapper setObject:self.userPassword forKey:kUserPasswordKey];
}

- (BOOL)canSendPost {
    return (self.userEmail && self.userPassword);
}

- (AFHTTPRequestOperation *)validateEmail:(NSString *)email password:(NSString *)password success:(void(^)(id response))success failure:(void(^)(NSError *error))failure {
    self.userEmail = email;
    self.userPassword = password;
    return [self requestOperationWithMethod:@"POST" path:VALIDATE_PATH parameters:nil success:^(AFHTTPRequestOperation *operation, id result) {
        [self storeCredentialsInKeychain];
        success(@"OK");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.userPassword = nil;
        self.userEmail = nil;
        NSLog(@"tumblr validation request failed %@", error.description);
    }];
}

- (AFHTTPRequestOperation *)sendPostWithTitle:(NSString *)title
                                         body:(NSString *)bodyText
                                      success:(void(^)(id response))success
                                      failure:(void(^)(NSError *error))failure {
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                title, @"title",
                                bodyText, @"body",
                                nil];
    
    return [self requestOperationWithMethod:@"POST"
                                     path:SEND_POST_PATH
                               parameters:parameters
                                  success:^(AFHTTPRequestOperation *operation, id result) {
                                      NSLog(@"TUMBLE POST COMPLETED %@", result);
                                      success(result);
                                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      NSLog(@"TUMBLR POST FAILED! %@", error.description);
                                      failure(error);
                                  }];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    
    NSMutableDictionary *allParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          self.userEmail,       @"email",
                                          self.userPassword,    @"password", nil];
    if (parameters) [allParameters addEntriesFromDictionary:parameters];
    
    return [super requestWithMethod:method
                               path:[[self.baseURL URLByAppendingPathComponent:path] absoluteString]
                         parameters:allParameters];
}

- (AFJSONRequestOperation *)requestOperationWithMethod:(NSString *)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters
                                               success:(OperationSuccess)success failure:(OperationFailure)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:parameters];
    NSLog(@"%@", request.URL.absoluteString);
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[self HTTPRequestOperationWithRequest:request
                                                                                         success:success
                                                                                         failure:failure];
    [op start];
    return op;
}


@end
