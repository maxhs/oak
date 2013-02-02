//
//  Utilities.h
//
//  Created by Max Haines-Stiles on 1/6/13.
//  Copyright (c) 2013 FOODIA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

+ (NSString *)accessToken;
+ (NSString *)userId;
+ (NSURL *)profileImageURLForFacebookID:(NSString *)fbid;
+ (NSString *)profileImagePathForUserId:(NSString *)uid;
+ (NSURL *)profileImageURLForUser:(NSString *)uid;
+ (NSURL *)profileImageURLForCurrentUser;
+ (NSString*)timeIntervalSinceStartDate:(NSDate*)date;
+ (void)alertWithTitle:(NSString *)title message:(NSString *)message;
+ (BOOL)currentDeviceIsRetina;
+ (NSString*)verboseTimeIntervalSinceStartDate:(NSDate*)date;
+ (NSString*)postedAt:(NSDate*)date;
+ (void)cacheUserProfileImage;
+ (void) cacheImage: (NSString *) ImageURLString;
+ (UIImage *) getCachedImage: (NSString *) ImageURLString;
+ (UIImage *) deleteCachedImage: (NSString *) ImageURLString;
@end
