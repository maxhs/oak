//
//  NSString+CamelCaseUnderscore.h
//  foodia
//
//  Created by Charles Mezak on 7/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CamelCaseUnderscore)
- (NSString *)toCamelCase;
- (NSString *)toUnderscore;
@end
