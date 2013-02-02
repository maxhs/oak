//
//  NSString+CamelCaseUnderscore.m
//  foodia
//
//  Created by Charles Mezak on 7/23/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "NSString+CamelCaseUnderscore.h"

@implementation NSString (CamelCaseUnderscore)
- (NSString *)toUnderscore {
    NSMutableString *output = [NSMutableString string];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    BOOL previousCharacterWasUppercase = FALSE;
    BOOL currentCharacterIsUppercase = FALSE;
    unichar currentChar = 0;
    unichar previousChar = 0;
    for (NSInteger idx = 0; idx < [self length]; idx += 1) {
        previousChar = currentChar;
        currentChar = [self characterAtIndex:idx];
        previousCharacterWasUppercase = currentCharacterIsUppercase;
        currentCharacterIsUppercase = [uppercase characterIsMember:currentChar];
        
        if (!previousCharacterWasUppercase && currentCharacterIsUppercase && idx > 0) {
            // insert an _ between the characters
            [output appendString:@"_"];
        } else if (previousCharacterWasUppercase && !currentCharacterIsUppercase) {
            // insert an _ before the previous character
            // insert an _ before the last character in the string
            if ([output length] > 1) {
                unichar charTwoBack = [output characterAtIndex:[output length]-2];
                if (charTwoBack != '_') {
                    [output insertString:@"_" atIndex:[output length]-1];
                }
            }
        } 
        // Append the current character lowercase
        [output appendString:[[NSString stringWithCharacters:&currentChar length:1] lowercaseString]];
    }
    return output;
}

- (NSString *)toCamelCase {
    NSMutableString *output = [NSMutableString string];
    NSCharacterSet *underscore = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    BOOL previousCharacterWasUnderscore = NO;
    unichar currentCharacter = 0;
    for (NSInteger i = 0; i < [self length]; i++) {
        currentCharacter = [self characterAtIndex:i];
        if ([underscore characterIsMember:currentCharacter]) {
            // if character is underscore, we note its existence, but don't add it to the output string
            previousCharacterWasUnderscore = YES;
        } else {
            // if the last character was an underscore, we capitalize this character and add it to the output
            if (previousCharacterWasUnderscore) {
                [output appendString:[[NSString stringWithCharacters:&currentCharacter length:1] uppercaseString]];
                previousCharacterWasUnderscore = NO;
            // otherwise, just add the character to the output string
            } else {
                [output appendString:[NSString stringWithCharacters:&currentCharacter length:1]];
            }
        }
    }
    return output;
}

@end
