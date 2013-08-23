//
//  Tools.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tools : NSObject

+ (NSDateFormatter *)dateFormatter;

// JSON
+ (NSString *)stringFromSourceIfNotNull:(id)source;
+ (NSNumber *)integerNumberFromSourceIfNotNull:(id)source;
+ (NSNumber *)booleanNumberFromSourceIfNotNull:(id)source withDefault:(BOOL)defaultValue;

// Strings
+ (NSString *)dateStringFromString:(NSString *)string withFormat:(NSString *)sourceFormat toFormat:(NSString *)resultFormat;
+ (NSString *)dateStringFromDateAndTimeString:(NSString *)string;
+ (NSString *)timeStringFromDateAndTimeString:(NSString *)string;

// Numbers
+ (NSDecimalNumber *)absoluteValueOfDecimalNumber:(NSDecimalNumber *)decimalNumber;

// Dates
+ (NSDate *)dateWithoutTimeFromDate:(NSDate *)date;
+ (NSDate *)dateWithSystemTimeFromDate:(NSDate *)date;

// Stuff
+ (BOOL)deviceIsiPad;

// Graphics
+ (void)addDropShadowToView:(UIView *)view color:(UIColor *)color opacity:(float)opacity radius:(CGFloat)radius offset:(CGSize)offset bounds:(CGRect)bounds;
+ (void)setMaskToView:(UIView *)view roundCorners:(UIRectCorner)corners radius:(CGFloat)radius;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(CGFloat)width;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToHeight:(CGFloat)height;
+ (CGRect)frameForImageInImageView:(UIImageView *)imageView;

// Animation
+ (CAAnimation *)fadeTransitionWithDuration:(CGFloat)duration;
+ (CAAnimation *)transitionWithType:(NSString *)type duration:(CGFloat)duration timingFunction:(CAMediaTimingFunction *)function;

// Layout
+ (void)addEdgeConstraint:(NSLayoutAttribute)edge superview:(UIView *)superview subview:(UIView *)subview;

@end
