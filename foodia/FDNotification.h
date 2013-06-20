//
//  FDNotification.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDRecord.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class FDUser, FDVenue;

@interface FDNotification : FDRecord

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * fromUserFbid;
@property (nonatomic, retain) NSString * fromUserId;
@property (nonatomic, retain) NSNumber * epochTime;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * notificationType;
@property (nonatomic, retain) NSNumber * targetPostId;
@property (nonatomic, retain) NSNumber * targetUserId;

+ (void)resetUserNotification;
- (NSDate *)postedAt;
- (NSString *)message;
- (NSString *)fromUserFbid;
- (NSString *)fromUserId;
- (NSString *)notificationType;
+ (FDNotification *)userNotification;
@end
