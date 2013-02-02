//
//  FoursquareCategory.h
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FoursquareCategory : NSObject <NSCoding> {
    NSString *foursquareCategoryId;
    NSString *name;
    NSString *pluralName;
    BOOL primary;
    NSString *shortName;
}

@property (nonatomic, copy) NSString *foursquareCategoryId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pluralName;
@property (nonatomic, assign) BOOL primary;
@property (nonatomic, copy) NSString *shortName;

+ (FoursquareCategory *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
