//
//  FDComment.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/23/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDRecord.h"

@class FDUser;

@interface FDComment : FDRecord
@property (nonatomic, strong) FDUser *user;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSNumber *epochTime;
- (NSDate *)date;
@end
