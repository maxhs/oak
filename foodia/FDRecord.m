//
//  FDRecord.m
//  foodia
//
//  Created by Charles Mezak on 7/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecord.h"
#import "NSString+CamelCaseUnderscore.h"


@implementation FDRecord

@synthesize identifier;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    } else {
        NSLog(@"undefined key: %@", key);
    }
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    NSMutableDictionary *camelDictonary = [NSMutableDictionary dictionaryWithCapacity:keyedValues.count];
    for (NSString *key in keyedValues.allKeys) {
        [camelDictonary setValue:[keyedValues objectForKey:key] forKey:[key toCamelCase]];
    }
    [super setValuesForKeysWithDictionary:camelDictonary];
}

//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    self = [super init];
    if (self) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{@"id" : self.identifier};
}

@end
