//
//  Utilities.h
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

// JSON input
+ (NSString *)stringFromSourceIfNotNull:(id)source;

+ (NSDecimalNumber *)decimalNumberFromSourceIfNotNull:(id)source;

+ (NSNumber *)integerNumberFromSourceIfNotNull:(id)source;

+ (NSNumber *)booleanNumberFromSourceIfNotNull:(id)source withDefault:(BOOL)defaultValue;

// String formatting
+ (NSString *)dateStringFromString:(NSString *)string withFormat:(NSString *)sourceFormat toFormat:(NSString *)resultFormat;

+ (NSString *)dateStringFromDateAndTimeString:(NSString *)string;

+ (NSString *)timeStringFromDateAndTimeString:(NSString *)string;

// Number formatting
+ (NSDecimalNumber *)absoluteValueOfDecimalNumber:(NSDecimalNumber *)decimalNumber;

// Miscellaneous
+ (void)setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners withRadius:(CGFloat)radius;

@end
