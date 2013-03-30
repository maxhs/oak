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

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * facebookId;
@property (nonatomic, retain) NSNumber *userId;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSNumber * invited;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * occupation;
@property (nonatomic, retain) NSString * avatarUrl;
@property (nonatomic, retain) NSString * authenticationToken;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
@end