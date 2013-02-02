//
//  FDVenueLocation.m
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDVenueLocation.h"

@implementation FDVenueLocation

- (NSString *)locality {
    NSMutableArray *components = [NSMutableArray array];
    if (self.address.length) [components addObject:self.address];
    if (self.city.length) [components addObject:self.city];
    if (self.state.length) [components addObject:self.state];
    return [components componentsJoinedByString:@", "];
}

- (BOOL)hasLocalityInfo {
    return self.city.length && self.state.length;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.cc forKey:@"cc"];
    [encoder encodeObject:self.city forKey:@"city"];
    [encoder encodeObject:self.country forKey:@"country"];
    [encoder encodeObject:self.distance forKey:@"distance"];
    [encoder encodeObject:self.lat forKey:@"lat"];
    [encoder encodeObject:self.lng forKey:@"lng"];
    [encoder encodeObject:self.postalCode forKey:@"postalCode"];
    [encoder encodeObject:self.state forKey:@"state"];
    [encoder encodeObject:self.address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.cc = [decoder decodeObjectForKey:@"cc"];
        self.city = [decoder decodeObjectForKey:@"city"];
        self.country = [decoder decodeObjectForKey:@"country"];
        self.distance = [decoder decodeObjectForKey:@"distance"];
        self.lat = [decoder decodeObjectForKey:@"lat"];
        self.lng = [decoder decodeObjectForKey:@"lng"];
        self.postalCode = [decoder decodeObjectForKey:@"postalCode"];
        self.state = [decoder decodeObjectForKey:@"state"];
        self.address = [decoder decodeObjectForKey:@"address"];
    }
    return self;
}

+ (FDVenueLocation *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    FDVenueLocation *instance = [[FDVenueLocation alloc] init];
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

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.cc) {
        [dictionary setObject:self.cc forKey:@"cc"];
    }

    if (self.city) {
        [dictionary setObject:self.city forKey:@"city"];
    }

    if (self.country) {
        [dictionary setObject:self.country forKey:@"country"];
    }

    if (self.distance) {
        [dictionary setObject:self.distance forKey:@"distance"];
    }

    if (self.lat) {
        [dictionary setObject:self.lat forKey:@"lat"];
    }

    if (self.lng) {
        [dictionary setObject:self.lng forKey:@"lng"];
    }

    if (self.postalCode) {
        [dictionary setObject:self.postalCode forKey:@"postalCode"];
    }

    if (self.state) {
        [dictionary setObject:self.state forKey:@"state"];
    }
    
    if (self.address) {
        [dictionary setObject:self.address forKey:@"address"];
    }

    return dictionary;

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {

}

@end
