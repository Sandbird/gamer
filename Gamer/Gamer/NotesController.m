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
	
	[self.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
	[self.textView setTextContainerInset:UIEdgeInsetsMake(15, 15, 15, 15)];
	
	self.context = [NSManagedObjectContext MR_contextForCurrentThread];
	
	if ([self.game.notes isEqualToString:@"(null)"]){
		[self.game setNotes:@""];
	}
	
	[self.textView setText:self.game.notes];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	if (self.textView.text.length == 0){
		[self.textView becomeFirstResponder];
	}
}

- (void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
	
	[self.game setNotes:self.textView.text];
	[self.context MR_saveToPersistentStoreAndWait];
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

@end
