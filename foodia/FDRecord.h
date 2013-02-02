//
//  FDRecord.h
//  foodia
//
//  Created by Charles Mezak on 7/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDRecord : NSObject <NSCoding>
@property (nonatomic, retain) NSString * identifier;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
@end
