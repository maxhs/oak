//
//  FDUser.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDUser.h"
#import "FDPost.h"


@implementation FDUser


@synthesize name,active,invited,following,facebookId;
@synthesize identifier, location, occupation;
//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    //[super encodeWithCoder:encoder];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.password forKey:@"password"];
    [encoder encodeObject:self.active forKey:@"active"];
    [encoder encodeObject:self.invited forKey:@"invited"];
    [encoder encodeObject:self.following forKey:@"following"];
    [encoder encodeObject:self.facebookId forKey:@"facebookId"];
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:self.avatarUrl forKey:@"avatarUrl"];
    [encoder encodeObject:self.authenticationToken forKey:@"authenticationToken"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if((self = [self init]))
    {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.password = [decoder decodeObjectForKey:@"password"];
        self.active = [decoder decodeObjectForKey:@"active"];
        self.invited = [decoder decodeObjectForKey:@"invited"];
        self.following = [decoder decodeObjectForKey:@"following"];
        self.facebookId = [decoder decodeObjectForKey:@"facebookId"];
        self.userId = [decoder decodeObjectForKey:@"userId"];
        self.avatarUrl = [decoder decodeObjectForKey:@"avatarUrl"];
        self.authenticationToken = [decoder decodeObjectForKey:@"authenticationToken"];
    }

    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {

        self.userId = [value stringValue];
    } else if ([key isEqualToString:@"fbid"]) {
        self.fbid = value;
    } else if ([key isEqualToString:@"email"]) {
        self.email = value;
    } else if ([key isEqualToString:@"password"]) {
        self.password = value;
    } else if([key isEqualToString:@"facebook_id"]) {
        self.facebookId = value;
    } else if([key isEqualToString:@"authentication_token"]) {
        self.authenticationToken = value;
    } else if([key isEqualToString:@"name"]) {
        self.name = value;
    } else if([key isEqualToString:@"active"]) {
        self.active = value;
    } else if([key isEqualToString:@"invited"]) {
        self.invited = value;
    } else if([key isEqualToString:@"following"]) {
        self.following = value;
    } else if([key isEqualToString:@"avatar_url"]) {
        self.avatarUrl = value;
    } else if([key isEqualToString:@"location"]) {
        self.location = value;
    } else if([key isEqualToString:@"occupation"]) {
        self.occupation = value;
    }
}


- (NSDictionary *)toDictionary {
    return @{@"name" : self.name, @"fbid" : self.facebookId,@"id" : self.userId};
}

//////////////////

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    NSMutableDictionary *camelDictonary = [NSMutableDictionary dictionaryWithCapacity:keyedValues.count];
    for (NSString *key in keyedValues.allKeys) {
        [camelDictonary setValue:[keyedValues objectForKey:key] forKey:key];
    }
    [super setValuesForKeysWithDictionary:keyedValues];
}


@end
