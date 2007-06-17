//
//  PreferencesController.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/24/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPrefsController.h"

@implementation MFPrefsController
- (id) init
{
	self = [super initWithWindowNibName:@"MacFusionPreferences"];
	return self;
}

- (void) windowDidLoad
{
	[[self window] center];
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
