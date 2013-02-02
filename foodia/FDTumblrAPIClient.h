//
//  FDTumblrAPIClient.h
//  foodia
//
//  Created by Charles Mezak and Max Haines-Stiles on 7/29/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface FDTumblrAPIClient : AFHTTPClient
+ (FDTumblrAPIClient *)sharedClient;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userPassword;

- (AFHTTPRequestOperation *)sendPostWithTitle:(NSString *)title
                                         body:(NSString *)bodyText
                                      success:(void(^)(id response))success
                                      failure:(void(^)(NSError *error))failure;

- (AFHTTPRequestOperation *)validateEmail:(NSString *)email
                                 password:(NSString *)password
                                  success:(void(^)(id response))success
                                  failure:(void(^)(NSError *error))failure;

@end
