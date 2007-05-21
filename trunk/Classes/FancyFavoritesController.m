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
	// Window settings
	[[self window] center];
//	// Do we want to float on top?
	[[self window] setLevel:NSFloatingWindowLevel];
	
	// Set up the buttons and menus
	NSMenu* editMenu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
	[editMenu addItemWithTitle: @"Edit" action:@selector(editFavorite:) keyEquivalent:@"e"];
	[editMenu addItemWithTitle: @"Delete" action:@selector(removeFavorite:) keyEquivalent:@"d"];
	[editButton setMenu: editMenu];
	[editButton setTarget: self];
	[addButton setMenu: [mainController filesystemTypesMenuWithTarget: self]];
	
	NSMenu* favoriteContextMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[favoriteContextMenu addItemWithTitle:@"Mount" action:@selector(mountFavorite:) keyEquivalent:@""];
	[favoriteContextMenu addItemWithTitle:@"Unmount" action:@selector(mountFavorite:) keyEquivalent:@""];
	[favoriteContextMenu addItemWithTitle:@"Edit" action:@selector(editFavorite:) keyEquivalent:@""];
	[favoriteContextMenu addItemWithTitle:@"Duplicate" action:@selector(duplicateFavorite:) keyEquivalent:@""];
	[favoritesTableView setMenu: favoriteContextMenu];
	
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

// Control the table's right click menu
- (BOOL) validateMenuItem:(NSMenuItem*)item
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];
	if ([item title] == @"Mount")
		return [mountButton isEnabled] && [[mountButton title] isEqualTo:@"Mount"];
	if ([item title] == @"Unmount")
		return [mountButton isEnabled] && [[mountButton title] isEqualTo:@"Unmount"];
	if ([item title] == @"Edit")
		return [editButton isEnabled];
	if ([item title] == @"Duplicate")
	{
		if ([fs status] == FuseFSStatusUnmounted)
			return YES;
		else
			return NO;
	}
	
	return YES;
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
			[mountButton setTitle:@"Mount"];
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

#pragma mark Action Methods
- (IBAction) removeFavorite:(id)sender
{
	id <FuseFSProtocol> fs = [[favoritesArrayController arrangedObjects] objectAtIndex: 
		[favoritesArrayController selectionIndex]];
	NSString* message = [NSString stringWithFormat: @"Are you sure you want to remove %@?", [fs name]];
	NSAlert* confirmationAlert = [NSAlert alertWithMessageText: message  defaultButton:@"OK" alternateButton:@"Cancel" 
												   otherButton:@"" informativeTextWithFormat:@""];
	[confirmationAlert setAlertStyle: NSWarningAlertStyle];
	[confirmationAlert setIcon: [NSImage imageNamed:@"MacFusion_Dialog_Question"]];
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
		[editButton highlight: NO];
		if (success)
		{
			[backup release];
			backup = nil;
		}
		else
		{
			[mainController willChangeValueForKey:@"favorites"];
			int oldIndex = [favoritesTableView selectedRow];
			[[mainController favorites] replaceObjectAtIndex:[[mainController favorites] indexOfObject: fs] 
												  withObject:backup];
			[mainController didChangeValueForKey:@"favorites"];
			
			// reset the selection to where it was before
			[favoritesTableView selectRow:oldIndex byExtendingSelection:NO];
			[backup release];
			backup = nil;
		}
		
		[mainController writeFavoritesToDefaults];
		return;
	}
	else // adding new favorite
	{
		if (success)
		{
			[mainController addFilesystemToFavorites: fs];
			[mainController mountFilesystem: fs];
			[mainController writeFavoritesToDefaults];
			return;
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
	
	if ([fs status] == FuseFSStatusUnmounted || [fs status] == FuseFSStatusMountFailed)
	{
		[mainController mountFilesystem: fs];
	}
	if ([fs status] == FuseFSStatusMounted)
	{
		[mainController unmountFilesystem: fs];
	}
}

- (IBAction) duplicateFavorite:(id)sender
{	
	// this method will only be called in favorite is unmounted state ... otherwise duplication is nasty
	// if a favorite is selected, we duplicate it
	id <FuseFSProtocol> fs = [[[favoritesArrayController arrangedObjects] objectAtIndex:
		[favoritesArrayController selectionIndex]] copyWithZone:nil];
	// but first we need to change the name by adding " copy" to the end
	NSString *newName = [NSString stringWithFormat: @"%@ copy", [fs name]];
	[fs setName:newName];	// set with setName: setter method from FuseFSProtocol
	
	if (fs)
	{
		[mainController addFilesystemToFavorites:fs];
		int newRow = [[favoritesArrayController arrangedObjects] indexOfObject:fs];
		[favoritesTableView selectRow:newRow byExtendingSelection:NO];
	}
	else
	{
		NSString *message = [NSString stringWithFormat:@"Couldn't duplicate this favorite"];
		NSAlert *errorAlert = [NSAlert alertWithMessageText:message	
											  defaultButton:@"OK" 
											alternateButton:@"" 
												otherButton:@"" 
								  informativeTextWithFormat:@""];
		[errorAlert setAlertStyle:NSWarningAlertStyle];
		[errorAlert setIcon: [NSImage imageNamed:@"MacFusion_Dialog_Warning"]];
		[errorAlert beginSheetModalForWindow:[self window] 
							   modalDelegate:self 
							  didEndSelector:nil 
								 contextInfo:nil];
		[fs release];	// release the object
	}
}

@end
