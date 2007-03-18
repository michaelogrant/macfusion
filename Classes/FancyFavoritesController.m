//
//  FancyFavoritesController.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/12/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "FancyFavoritesController.h"

@interface FancyFavoritesController (PrivateAPI)
- (void) updateUI;
@end

@implementation FancyFavoritesController
- (id) init
{
	self = [super init];
	[self initWithWindowNibName:@"FancyFavorites"];
	mainController = [[NSApplication sharedApplication] delegate];
	return self;
}

- (void) windowDidLoad
{
	// Set up the buttons and menus
	NSMenu* editMenu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
	[editMenu addItemWithTitle: @"Edit" action:@selector(editFavorite:) keyEquivalent:@"e"];
	[editMenu addItemWithTitle: @"Delete" action:@selector(removeFavorite:) keyEquivalent:@"d"];
	[editButton setMenu: editMenu];
	[editButton setTarget: self];
	[addButton setMenu: [mainController filesystemTypesMenuWithTarget: self]];
	
	// Set up our table
	NSCell* customNameDescriptionCell = [[[MacFusionFSCell alloc] init] autorelease];
	NSCell* customStatusCell = [[[MacFusionStatusCell alloc] init] autorelease];
	
	[customStatusCell setFont: [NSFont systemFontOfSize: 12]];
	
	[[favoritesTableView tableColumnWithIdentifier: @"name"] setDataCell: 
		customNameDescriptionCell];
	
	[[favoritesTableView tableColumnWithIdentifier: @"status"] setDataCell: 
		customStatusCell];
	[favoritesTableView setDoubleAction: @selector(editFavorite:)];
	
	// Watch for interface updates
	[favoritesArrayController addObserver: self forKeyPath:@"selection.status" options:NSKeyValueObservingOptionNew context:nil];
	
	[self updateUI];
}

// Update the table's right click menu
- (void) menuNeedsUpdate:(NSMenu*)menu
{
	// Clear Previous Menu
	NSEnumerator* mEnum = [[menu itemArray] objectEnumerator];
	NSMenuItem* i;
	while(i = [mEnum nextObject])
		[menu removeItem:i];
}

// Method to update the UI ... called when selection or status changed
// Is there a better way to do this?
- (void) updateUI
{
	if ([favoritesArrayController selectionIndex] == NSNotFound)
	{
		[editButton setEnabled: NO];
		[mountButton setEnabled: YES];
		[removeButton setEnabled: NO];
	}
	else
	{
		id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
			[favoritesArrayController selectionIndex]];
		
		[removeButton setEnabled: YES];
		if ([fs status] == FuseFSStatusMounted)
		{
			[editButton setEnabled: NO];
			[mountButton setEnabled: YES];
			[mountButton setTitle: @"Unmount"];
			[mountButton setKeyEquivalent: @"u"];
		}
		else if ([fs status] == FuseFSStatusUnmounted)
		{
			[editButton setEnabled: YES];
			[mountButton setEnabled: YES];
			[mountButton setTitle: @"Mount"];
			[mountButton setKeyEquivalent: @"m"];
		}
		else if ([fs status] == FuseFSStatusWaitingToMount)
		{
			[mountButton setEnabled: NO];
			[editButton setEnabled: NO];
		}
		else if ([fs status] == FuseFSStatusMountFailed)
		{
			[editButton setEnabled: YES];
			[mountButton setEnabled: YES];
		}
	}
}

// methods to called the UI updating code
// we need to update the UI when selection changes or when status changes
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self updateUI];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
								 change:(NSDictionary *)change 
								context:(void *)context
{
	[self updateUI];
}

- (IBAction) removeFavorite:(id)sender
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];
	NSString* message = [NSString stringWithFormat: @"Are you sure you want to remove %@?", [fs name]];
	NSAlert* confirmationAlert = [NSAlert alertWithMessageText: message  defaultButton:@"OK" alternateButton:@"Cancel" 
												   otherButton:@"" informativeTextWithFormat:@""];
	[confirmationAlert setAlertStyle: NSWarningAlertStyle];
	[confirmationAlert beginSheetModalForWindow: [self window] modalDelegate:self 
								 didEndSelector:@selector(removeFavoriteConfirmationAlertDidEnd:returnCode:favorite:) contextInfo:fs];
}

- (void) removeFavoriteConfirmationAlertDidEnd:(NSAlert*)alert returnCode:(int)code favorite:(id)fs
{
	if (code == NSAlertDefaultReturn)
	{
		[favoritesArrayController removeObject: fs];
		if ([fs status] == FuseFSStatusMounted)
		{
			[mainController unmountFilesystem: fs];
		}
	}
	else
		return;
}

- (void) filesystemTypeChosen:(NSMenuItem*)item
{
	Class fsClass = [item representedObject];
	id <FuseFSProtocol> fs = [[fsClass alloc] init];
	[addButton highlight:YES];
	[EditController editFilesystem: fs 
						  onWindow: [self window]
					  notifyTarget: self];
}

- (IBAction) editFavorite:(id)sender
{
	if ([favoritesArrayController selectionIndex] == NSNotFound)
		return;
	else
	{
		id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
			[favoritesArrayController selectionIndex]];
		if ([fs status] == FuseFSStatusMounted)
			return; // Don't edit a mounted favorite
		backup = [fs copyWithZone:nil];
		[editButton highlight:YES];
		[EditController editFilesystem: fs 
								onWindow: [self window] 
								notifyTarget: self];
	}
}

- (void) editCompleteForFilesystem:(id <FuseFSProtocol>)fs
					 WithSuccess:(BOOL)success
{	
	if ([[mainController favorites] containsObject: fs]) // editing existing favorite
	{
		if (success)
		{
			[backup release];
			backup = nil;
			return;
		}
		else
		{
			[mainController willChangeValueForKey:@"favorites"];
			[[mainController favorites] replaceObjectAtIndex:[[mainController favorites] indexOfObject: fs] 
												  withObject:backup];
			[mainController didChangeValueForKey:@"favorites"];
			
			[backup release];
			backup = nil;
			return;
		}
		
		[editButton highlight: NO];
	}
	else // adding new favorite
	{
		if (success)
		{
			[mainController addFilesystemToFavorites: fs];
			[mainController mountFilesystem: fs];
		}
		else
		{
			[fs release];
		}
		[addButton highlight:NO];
	}
}

- (IBAction) mountFavorite:(id)sender
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


@end
