//
//  FDVenueContact.h
//  
//
//  Created by Max Haines-Stiles on 1/4/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDVenueContact : NSObject <NSCoding> {
    NSString *formattedPhone;
    NSString *phone;
}

@property (nonatomic, copy) NSString *formattedPhone;
@property (nonatomic, copy) NSString *phone;

+ (FDVenueContact *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
