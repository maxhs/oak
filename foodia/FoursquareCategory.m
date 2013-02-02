//
//  FoursquareCategory.m
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FoursquareCategory.h"

@implementation FoursquareCategory

@synthesize foursquareCategoryId;
@synthesize name;
@synthesize pluralName;
@synthesize primary;
@synthesize shortName;

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.foursquareCategoryId forKey:@"foursquareCategoryId"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.pluralName forKey:@"pluralName"];
    [encoder encodeObject:[NSNumber numberWithBool:self.primary] forKey:@"primary"];
    [encoder encodeObject:self.shortName forKey:@"shortName"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.foursquareCategoryId = [decoder decodeObjectForKey:@"foursquareCategoryId"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.pluralName = [decoder decodeObjectForKey:@"pluralName"];
        self.primary = [(NSNumber *)[decoder decodeObjectForKey:@"primary"] boolValue];
        self.shortName = [decoder decodeObjectForKey:@"shortName"];
    }
    return self;
}

+ (FoursquareCategory *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    FoursquareCategory *instance = [[FoursquareCategory alloc] init];
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

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{

    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"foursquareCategoryId"];
    }

}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.foursquareCategoryId) {
        [dictionary setObject:self.foursquareCategoryId forKey:@"foursquareCategoryId"];
    }

    if (self.name) {
        [dictionary setObject:self.name forKey:@"name"];
    }

    if (self.pluralName) {
        [dictionary setObject:self.pluralName forKey:@"pluralName"];
    }

    [dictionary setObject:[NSNumber numberWithBool:self.primary] forKey:@"primary"];

    if (self.shortName) {
        [dictionary setObject:self.shortName forKey:@"shortName"];
    }

    return dictionary;

}

@end
