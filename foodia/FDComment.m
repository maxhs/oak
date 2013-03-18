//
//  FDComment.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/23/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDComment.h"
#import "FDUser.h"

@implementation FDComment

@synthesize body;

- (NSDate *)date {
    return [NSDate dateWithTimeIntervalSince1970:self.epochTime.integerValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.body forKey:@"body"];
    [encoder encodeObject:self.user forKey:@"user"];
    [encoder encodeObject:self.epochTime forKey:@"epochTime"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.body = [decoder decodeObjectForKey:@"body"];
        self.user = [decoder decodeObjectForKey:@"user"];
        self.epochTime = [decoder decodeObjectForKey:@"epochTime"];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"user"]) {
        FDUser *user = [[FDUser alloc] initWithDictionary:value];
        [self setUser:user];
    } else {
        [super setValue:value forKey:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [super setValue:value forUndefinedKey:key];
}

@end
