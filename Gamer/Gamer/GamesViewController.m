//
//  GamesViewController.m
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "GamesViewController.h"
#import "GamesCell.h"
#import "Game.h"

@interface GamesViewController ()

@end

@implementation GamesViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return _games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	GamesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GamesCell"];
	
	Game *game = _games[indexPath.row];
	[cell.titleLabel setText:game.title];
//	[cell.imageView setImage:game.coverImage];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
}

@end
