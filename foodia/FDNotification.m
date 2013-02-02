//
//  FDNotification.m
//  foodia
//
//  Created by Max Haines-Stiles on 1/22/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDNotification.h"
#import "FDUser.h"
#import "FDComment.h"

@implementation FDNotification

static FDNotification *userNotification;

+ (void)initialize {
    if (self == [FDNotification class]){
        
        userNotification = [FDNotification new];
    }
}

+ (FDNotification *)userNotification {
    return userNotification;
}

+ (void)resetUserNotification {
    userNotification = [FDNotification new];
}

- (NSDate *)postedAt {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.epochTime.floatValue];
    return date;
}


#pragma mark - Coding Methods

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"user"]) {
        
    } else {
        [super setValue:value forKey:key];
        
    }
}


//===========================================================
//  Keyed Archiving
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.epochTime forKey:@"epochTime"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.epochTime = [decoder decodeObjectForKey:@"epochTime"];
    }
    return self;
}

@end
