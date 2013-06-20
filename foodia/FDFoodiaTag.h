//
//  FDFoodiaTag.h
//  foodia
//
//  Created by Max Haines-Stiles on 5/18/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDUser.h"
#import "FDRecord.h"

@interface FDFoodiaTag : NSObject
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSArray *foodiaObjects;
@property (strong, nonatomic) NSArray *postsArray;
@property (strong, nonatomic) NSString *color;
@property (strong, nonatomic) NSNumber *postsCount;
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end
