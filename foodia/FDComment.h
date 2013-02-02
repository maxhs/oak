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
@property (nonatomic, retain) FDUser *user;
@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) NSNumber *epochTime;
- (NSDate *)date;
@end
