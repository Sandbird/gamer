//
//  SearchResult.h
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResult : NSObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageURL;


@end
