//
//  FDFoodiaTag.m
//  foodia
//
//  Created by Max Haines-Stiles on 5/18/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "FDFoodiaTag.h"

@implementation FDFoodiaTag

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"name"]) {
        self.name = value;
    } else if ([key isEqualToString:@"user_id"] || [key isEqualToString:@"userId"]) {
        self.userId = value;
    } else if ([key isEqualToString:@"id"] || [key isEqualToString:@"identifier"]) {
        self.identifier = value;
    } else if ([key isEqualToString:@"posts"]) {
        self.postsArray = value;
    } else if ([key isEqualToString:@"color"]) {
        self.color = value;
    } else if ([key isEqualToString:@"posts_count"]) {
        self.postsCount = value;
    } else {
        //[super setValue:value forUndefinedKey:key];
    }
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [super setValuesForKeysWithDictionary:keyedValues];
}

@end
