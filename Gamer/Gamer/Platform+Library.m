//
//  Platform+Library.m
//  Gamer
//
//  Created by Caio Mello on 12/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "Platform+Library.h"
#import "Release.h"
#import "Metascore.h"

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
	
	NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
	return [libraryGames sortedArrayUsingDescriptors:@[titleSortDescriptor]];
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
	
	NSSortDescriptor *releaseDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES];
	return [gameReleases sortedArrayUsingDescriptors:@[releaseDateSortDescriptor]];
}

- (Metascore *)metascoreWithGame:(Game *)game{
	for (Metascore *metascore in self.metascores){
		if (metascore.game == game){
			return metascore;
		}
	}
	
	return nil;
}

@end
