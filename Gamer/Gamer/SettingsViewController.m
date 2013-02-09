//
//  SettingsViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "SettingsViewController.h"
#import "Game.h"
#import "Genre.h"
#import "Platform.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)requestGameWithIdentifier:(NSString *)identifier{
	NSString *url = [NSString stringWithFormat:@"http://api.giantbomb.com/game/%@/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&format=json&field_list=deck,developers,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,images,name,original_release_date,platforms,publishers,releases,similar_games,themes,videos", identifier];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"Success in %@ - Status code: %d - Search", self, response.statusCode);
		
		NSLog(@"%@", JSON);
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Failure in %@ - Status code: %d - Search", self, response.statusCode);
	}];
	[operation start];
}

- (IBAction)testButtonPressAction:(id)sender{
	// http://api.giantbomb.com/game/26801/?api_key=d92c258adb509ded409d28f4e51de2c83e297011&id=26801&format=json
	
	// MGSR: 26801
	// GoWJ: 38481
	// WDogs: 38538
	
	[self requestGameWithIdentifier:@"38481"];
}

- (IBAction)clearDatabaseButtonPressAction:(UIButton *)sender{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	[Game truncateAll];
	[Genre truncateAll];
	[Platform truncateAll];
	[Developer truncateAll];
	[Publisher truncateAll];
	[Franchise truncateAll];
	[Theme truncateAll];
	[context saveToPersistentStoreAndWait];
}

@end
