//
//  Platform+Library.m
//  Gamer
//
//  Created by Caio Mello on 12/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "Platform+Library.h"

@implementation Platform (Library)

- (BOOL)containsLibraryGames{
	for (Game *game in self.addedGames){
		if ([game.location isEqualToNumber:@(GameLocationLibrary)]){
			return YES;
		}
	}
	
	return NO;
}

- (NSArray *)sortedLibraryGames{
	NSArray *libraryGames = [self.addedGames.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"location = %@", @(GameLocationLibrary)]];
	
	return [libraryGames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Game *game1 = (Game *)obj1;
		Game *game2 = (Game *)obj2;
		return [game1.title compare:game2.title] == NSOrderedAscending;
	}];
}

@end
