//
//  Tools.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "Tools.h"

@implementation Tools

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

static NSDateFormatter *DATEFORMATTER;

+ (NSDateFormatter *)dateFormatter{
	if (!DATEFORMATTER) DATEFORMATTER = [[NSDateFormatter alloc] init];
	[DATEFORMATTER setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	return DATEFORMATTER;
}

#pragma mark - JSON

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
	return (source != [NSNull null]) ? @([[NSString stringWithFormat:@"%@", source] boolValue]) : @(defaultValue);
}

#pragma mark - Strings

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

#pragma mark - Numbers

+ (NSDecimalNumber *)absoluteValueOfDecimalNumber:(NSDecimalNumber *)decimalNumber{
	if ([decimalNumber compare:[NSDecimalNumber zero]] == NSOrderedAscending){
		NSDecimalNumber *negativeOne = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:YES];
		return [decimalNumber decimalNumberByMultiplyingBy:negativeOne];
	}
	
	return decimalNumber;
}

#pragma mark - Dates

+ (NSDate *)dateWithoutTimeFromDate:(NSDate *)date{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];
	return [calendar dateFromComponents:dateComponents];
}

+ (NSDate *)dateWithSystemTimeFromDate:(NSDate *)date{
	NSInteger GMTOffset = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] secondsFromGMTForDate:date];
	NSInteger localOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:date];
	NSTimeInterval interval = GMTOffset - localOffset;
	
	return [NSDate dateWithTimeInterval:interval sinceDate:date];
}

#pragma mark - Graphics

+ (void)addDropShadowToView:(UIView *)view color:(UIColor *)color opacity:(float)opacity radius:(CGFloat)radius offset:(CGSize)offset{
	[view setClipsToBounds:NO];
	[view.layer setShadowPath:[UIBezierPath bezierPathWithRect:view.bounds].CGPath];
	[view.layer setShadowColor:color.CGColor];
	[view.layer setShadowOpacity:opacity];
	[view.layer setShadowRadius:radius];
	[view.layer setShadowOffset:offset];
}

+ (void)setMaskToView:(UIView *)view roundCorners:(UIRectCorner)corners radius:(CGFloat)radius{
	UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
	
	CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
	[shapeLayer setPath:bezierPath.CGPath];
	
	view.layer.mask = shapeLayer;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(CGFloat)width{
	CGFloat scaleFactor = width/image.size.width;
	
	CGFloat newWidth = image.size.width * scaleFactor;
	CGFloat newHeight = image.size.height * scaleFactor;
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), YES, 0);
	CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToHeight:(CGFloat)height{
	CGFloat scaleFactor = height/image.size.height;
	
	CGFloat newWidth = image.size.width * scaleFactor;
	CGFloat newHeight = image.size.height * scaleFactor;
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), YES, 0);
	CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
	[image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end
