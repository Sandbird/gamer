//
//  Platform+Library.h
//  Gamer
//
//  Created by Caio Mello on 12/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "Platform.h"

@interface Platform (Library)

- (BOOL)containsLibraryGames;
- (NSArray *)sortedLibraryGames;

- (BOOL)containsReleasesWithGame:(Game *)game;
- (NSArray *)sortedReleasesWithGame:(Game *)game;

- (Metascore *)metascoreWithGame:(Game *)game;

@end
