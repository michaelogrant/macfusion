//
//  PreferencesController.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/24/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController
- (id) init
{
	self = [super initWithWindowNibName:@"MacFusionPreferences"];
	return self;
}

- (void) windowDidLoad
{
	
}

- (IBAction) loginItemChanged:(id) sender
{
	MacFusionController* mainController = [[NSApplication sharedApplication] delegate];
	[mainController setLoginItemEnabled: [sender state]];
}

- (IBAction) sleepUnmountChanged:(id) sender
{
}

@end
