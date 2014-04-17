//
//  Platform+Library.m
//  Gamer
//
//  Created by Caio Mello on 12/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "Platform+Library.h"
#import "Release.h"

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
		return [game1.title compare:game2.title] == NSOrderedDescending;
	}];
}

- (BOOL)containsReleasesWithGame:(Game *)game{
	for (Release *release in self.releases){
		if (release.game == game){
			return YES;
		}
	}
	
	return NO;
}

- (NSArray *)sortedReleasesWithGame:(Game *)game{
	NSArray *gameReleases = [self.releases.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"game = %@", game]];
	
	return [gameReleases sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		Release *release1 = (Release *)obj1;
		Release *release2 = (Release *)obj2;
		return [release1.releaseDate compare:release2.releaseDate] == NSOrderedAscending;
	}];
}

@end
