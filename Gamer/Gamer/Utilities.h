//
//  Utilities.h
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

+ (NSDateFormatter *)dateFormatter;

// JSON input
+ (NSString *)stringFromSourceIfNotNull:(id)source;

+ (NSNumber *)integerNumberFromSourceIfNotNull:(id)source;

+ (NSNumber *)booleanNumberFromSourceIfNotNull:(id)source withDefault:(BOOL)defaultValue;

// String formatting
+ (NSString *)dateStringFromString:(NSString *)string withFormat:(NSString *)sourceFormat toFormat:(NSString *)resultFormat;

+ (NSString *)dateStringFromDateAndTimeString:(NSString *)string;

+ (NSString *)timeStringFromDateAndTimeString:(NSString *)string;

// Number formatting
+ (NSDecimalNumber *)absoluteValueOfDecimalNumber:(NSDecimalNumber *)decimalNumber;

// Date formatting
+ (NSDate *)localDateWithDate:(NSDate *)date;

// Graphics
+ (void)addDropShadowToView:(UIView *)view color:(UIColor *)color opacity:(float)opacity radius:(CGFloat)radius offset:(CGSize)offset;

+ (void)setMaskToView:(UIView *)view roundCorners:(UIRectCorner)corners radius:(CGFloat)radius;

@end
