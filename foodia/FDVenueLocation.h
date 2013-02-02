//
//  FDVenueLocation.h
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDVenueLocation : NSObject <NSCoding>

@property (nonatomic, copy) NSString *cc;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSNumber *distance;
@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;
@property (nonatomic, copy) NSString *postalCode;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *address;

- (NSString *)locality;
- (BOOL)hasLocalityInfo;

+ (FDVenueLocation *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
