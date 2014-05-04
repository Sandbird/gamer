//
//  NotesController.m
//  Gamer
//
//  Created by Caio Mello on 04/05/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "NotesController.h"

@interface NotesController () <UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UITextView *textView;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation NotesController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
	[_textView setTextContainerInset:UIEdgeInsetsMake(15, 15, 15, 15)];
	
	_context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	if ([_game.notes isEqualToString:@"(null)"]){
		[_game setNotes:@""];
	}
	
	[_textView setText:_game.notes];
}

- (void)viewDidAppear:(BOOL)animated{
	if (_textView.text.length == 0){
		[_textView becomeFirstResponder];
	}
}

- (void)viewDidDisappear:(BOOL)animated{
	[_game setNotes:_textView.text];
	[_context MR_saveToPersistentStoreAndWait];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

@end
