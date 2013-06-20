//
//  FDUser.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FDRecord.h"

@class FDPost;

@interface FDUser : NSObject <NSCoding>

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * facebookId;
@property (nonatomic, strong) NSString * fbid;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSNumber * active;
@property (nonatomic, strong) NSNumber * following;
@property (nonatomic, strong) NSNumber * invited;
@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, strong) NSString * location;
@property (nonatomic, strong) NSString * occupation;
@property (nonatomic, strong) NSString * avatarUrl;
@property (nonatomic, strong) NSString * authenticationToken;
@property (nonatomic, strong) NSString * philosophy;
@property (nonatomic) BOOL pushSmile;
@property (nonatomic) BOOL pushFollow;
@property (nonatomic) BOOL pushGeofence;
@property (nonatomic) BOOL pushComment;
@property (nonatomic) BOOL pushFeature;
@property (nonatomic) BOOL emailNotifications;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
@end