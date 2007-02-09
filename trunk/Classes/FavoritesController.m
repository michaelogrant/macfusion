//
//  FavoritesController.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/19/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FavoritesController.h"
@interface FavoritesController (PrivateAPI)
- (void) adjustUIForSelectedFS;
@end

@implementation FavoritesController

- (id) init
{
	self = [super init];
	mainController = [[NSApplication sharedApplication] delegate];
	[self initWithWindowNibName:@"Favorites"];
	fsControllers = [[NSMutableArray alloc] init];
	return self;
}

- (void) windowDidLoad
{
	[tableView setNeedsDisplay: YES];
	[tableView reloadData];
	[[self window] makeKeyAndOrderFront: self];
	[favoritesArrayController addObserver: self forKeyPath:@"selection.status" options:NSKeyValueObservingOptionNew context:nil];
	[self adjustUIForSelectedFS];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowClosed:) name:
				  NSWindowWillCloseNotification object:nil];
}

- (void) handleWindowClosed:(NSNotification*)note
{
	[fsControllers removeObject: [[note object] windowController]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
	if (keyPath == @"selection.status")
	{
		[self adjustUIForSelectedFS];
	}
}

- (void) adjustUIForSelectedFS
{
	if ([[favoritesArrayController selectedObjects] count] == 0)
	{
		[editButton setEnabled: NO];
		[mountButton setEnabled: NO];
	}
	else
	{
		id <FuseFSProtocol> fs = [[favoritesArrayController selectedObjects] objectAtIndex: 0];
		if ([fs status] == FuseFSStatusMounted)
		{
			[mountButton setEnabled: YES];
			[mountButton setTitle:@"Unmount"];
			[editButton setEnabled: NO];
			[mountButton setKeyEquivalent:@"u"];
		}
		else if ([fs status] == FuseFSStatusUnmounted)
		{
			[mountButton setTitle:@"Mount"];
			[editButton setEnabled: YES];
			[mountButton setKeyEquivalent:@"m"];
		}
		else
		{
			[mountButton setEnabled: NO];
			[editButton setEnabled: NO];
		}
	}
}

- (IBAction) addFavorite:(id)sender
{
	MountController* mountController = [[MountController alloc] init];
	[mountController setForAddingFavorite];
	[fsControllers addObject: mountController];
	[mountController release];
}

- (IBAction) removeFavorite:(id)sender
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];
	[favorites removeObject: fs];
	[favoritesArrayController removeObject: fs];
	[tableView reloadData];
}

- (IBAction) modifyFavorite:(id)sender
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];

	MountController* mountController = [[MountController alloc] init];
	[mountController setForEditingFavorite: fs];
	[fsControllers addObject: mountController];
	[mountController release];
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self adjustUIForSelectedFS];
}

- (IBAction) mountButtonClicked:(id)sender
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];
	if ([fs status] == FuseFSStatusUnmounted)
	{
		[mainController mountFilesystem: fs];
	}
	if ([fs status] == FuseFSStatusMounted)
	{
		[mainController unmountFilesystem: fs];
	}
}

- (void) dealloc 
{
	[fsControllers release];
	[super dealloc];
}

@end