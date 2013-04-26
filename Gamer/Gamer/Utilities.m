//
//  Utilities.m
//  Gamer
//
//  Created by Caio Mello on 4/23/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

//	dispatch_async(dispatch_get_main_queue(), ^{
//	});

//	CATransition *transition = [CATransition animation];
//	transition.type = kCATransitionFade;
//	transition.duration = 0.2;
//	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//	[view.layer addAnimation:transition forKey:nil];

//	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
//	animation.duration = 0.3;
//	animation.toValue = [NSValue valueWithCGPoint:CGPointMake(view.layer.position.x, view.layer.position.y + 20)];
//	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
//	[view.layer addAnimation:animation forKey:@"position"];
//	view.layer.position = CGPointMake(view.layer.position.x, view.layer.position.y + 20);

#pragma mark - JSON input

+ (NSString *)stringFromSourceIfNotNull:(id)source{
	return (source != [NSNull null]) ? [NSString stringWithFormat:@"%@", source] : nil;
}

+ (NSDecimalNumber *)decimalNumberFromSourceIfNotNull:(id)source{
	return (source != [NSNull null]) ? [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", source]] : [NSDecimalNumber zero];
}

+ (NSNumber *)integerNumberFromSourceIfNotNull:(id)source{
	return (source != [NSNull null]) ? @([[NSString stringWithFormat:@"%@", source] integerValue]) : @(0);
}

+ (NSNumber *)booleanNumberFromSourceIfNotNull:(id)source withDefault:(BOOL)defaultValue{
	return (source != [NSNull null]) ? [NSNumber numberWithBool:[[NSString stringWithFormat:@"%@", source] boolValue]] : [NSNumber numberWithBool:defaultValue];
}

#pragma mark - String formatting

+ (NSString *)dateStringFromString:(NSString *)string withFormat:(NSString *)sourceFormat toFormat:(NSString *)resultFormat{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:sourceFormat];
	NSDate *date = [dateFormatter dateFromString:string];
	[dateFormatter setDateFormat:resultFormat];
	return [dateFormatter stringFromDate:date];
}

+ (NSString *)dateStringFromDateAndTimeString:(NSString *)string{
	NSString *date = ([string componentsSeparatedByString:@" "])[0];
	return [self dateStringFromString:date withFormat:@"yyyy-MM-dd" toFormat:@"dd/MM/yyyy"];
}

+ (NSString *)timeStringFromDateAndTimeString:(NSString *)string{
	NSString *time = ([string componentsSeparatedByString:@" "])[1];
	return [NSString stringWithFormat:@"%@:%@", ([time componentsSeparatedByString:@":"])[0], ([time componentsSeparatedByString:@":"])[1]];
}

#pragma mark - Number formatting

+ (NSDecimalNumber *)absoluteValueOfDecimalNumber:(NSDecimalNumber *)decimalNumber{
	if ([decimalNumber compare:[NSDecimalNumber zero]] == NSOrderedAscending){
		NSDecimalNumber *negativeOne = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:YES];
		return [decimalNumber decimalNumberByMultiplyingBy:negativeOne];
	}
	
	return decimalNumber;
}

#pragma mark - Miscellaneous

+ (void)setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners withRadius:(CGFloat)radius{
	//	[view.layer setMasksToBounds:YES];
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
	
	CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
	[shapeLayer setPath:bezierPath.CGPath];
	
	view.layer.mask = shapeLayer;
}

@end
