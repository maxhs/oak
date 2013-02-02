//
//  FDVenueContact.m
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDVenueContact.h"

@implementation FDVenueContact

@synthesize formattedPhone;
@synthesize phone;

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.formattedPhone forKey:@"formattedPhone"];
    [encoder encodeObject:self.phone forKey:@"phone"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.formattedPhone = [decoder decodeObjectForKey:@"formattedPhone"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
    }
    return self;
}

+ (FDVenueContact *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    FDVenueContact *instance = [[FDVenueContact alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;

}

- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary
{

    if (![aDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }

    [self setValuesForKeysWithDictionary:aDictionary];

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.formattedPhone) {
        [dictionary setObject:self.formattedPhone forKey:@"formattedPhone"];
    }

    if (self.phone) {
        [dictionary setObject:self.phone forKey:@"phone"];
    }

    return dictionary;

}

@end
