//
//  QuickMountController.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MountController.h"
#import "SSHFS.h"

@interface MountController (PrivateAPI)
- (NSView*)getLastKeyViewInView:(NSView*)input;
@end

@implementation MountController

- (id) init
{
	mainController = [[NSApplication sharedApplication] delegate];
	plugins = [mainController plugins];
	[super initWithWindowNibName:@"Mount"];
	[[self window] setDelegate: self];
	initialRect = [[self window] frame];
	return self;
}

- (void) setForEditingFavorite: (id <FuseFSProtocol>)fs
{
	[fs retain];
	fileSystem = fs;
	mode = FavoriteEditMode;
	
	[FSTypePopup selectItemWithTitle: [fileSystem fsLongType]];
	[[self window] setTitle: 
		[NSString stringWithFormat: @"Editing Favorite: %@", [fileSystem name]]];
	[FSTypePopup setEnabled: NO];
	[endButton setTitle:@"OK"];
	[endButton setHidden: NO];
	[switchButton setHidden: YES];
	
	[self FSTypeChanged: self];
	[super showWindow: self];
}

- (void) setForAddingFavorite
{
	mode = FavoriteAddMode;
	[[self window] setTitle: @"Add Favorite"];
	[switchButton setTitle: @"Mount Now"];
	[switchButton setHidden: NO];
	[endButton setTitle: @"Add"];
	[endButton setHidden: NO];
	[[super window] makeKeyAndOrderFront: self];
}

- (void) setForQuickMount
{
	mode = QuickMountMode;
	[switchButton setHidden: NO];
	[switchButton setTitle: @"Add to Favorites"];
	[endButton setHidden: NO];
	[endButton setTitle: @"Mount"];
	[super showWindow: self];
}

// method to clear everything
- (void) clear
{
	[configurationView removeFromSuperview];
	[fileSystem release];
	[fsUIController release];
	fileSystem = nil;
	fsUIController = nil;
//	[endButton setHidden: YES];
//	[switchButton setHidden: YES];
	[[self window] setFrame: initialRect display:YES animate:YES];
	previousFSType = nil;
}

- (void) windowDidLoad
{
	NSString* fsTypeName;
	NSMenu* m = [[NSMenu alloc] initWithTitle:@"Filesystem Types"];
	[m addItemWithTitle:selectTypeMenuItemName action:nil keyEquivalent:@""];
	
	NSEnumerator* e = [plugins keyEnumerator];
	while(fsTypeName = [e nextObject])
	{
		NSString* menuTitle = [[[plugins objectForKey:fsTypeName] infoDictionary]
			objectForKey:@"FSLongType"];
		
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle: menuTitle
													  action:nil
											   keyEquivalent:@""];
		[item setRepresentedObject: [plugins objectForKey:fsTypeName]];
		[m addItem: item];
		[item release];
	}
	
	[FSTypePopup setMenu: m];
	[m release];
}

- (IBAction)FSTypeChanged:(id)sender
{	
	if ([[FSTypePopup selectedItem] title] != selectTypeMenuItemName &&
		[[FSTypePopup selectedItem] title] != previousFSType)
	{
		[[FSTypePopup itemWithTitle:selectTypeMenuItemName] setEnabled: NO];
		
		// clear previous stuff
		if (mode == FavoriteAddMode || QuickMountMode)
		{
			[fileSystem release];
			[fsUIController release];
		}

		// get the bundle for the plugin we're using
		NSBundle* b = [[FSTypePopup selectedItem] representedObject];
		
		// instantiate the UI controller
		NSString* UIClassName = [[b infoDictionary] 
			objectForKey:@"UIClassName"];
		Class UIControllerClass = [b classNamed:UIClassName];
		
		if (mode == FavoriteAddMode || mode == QuickMountMode)
		{
			fsUIController = [[UIControllerClass alloc] init];
			// get the created fileSystem
			fileSystem = [fsUIController fileSystem];
		}
		else if (mode == FavoriteEditMode)
		{
			fsUIController = [[UIControllerClass alloc] 
				initWithFS: fileSystem];
		}
		
		// display the correct configuration view
		NSView* pluginView = [fsUIController configurationView];
		[pluginView setFrameOrigin: NSMakePoint(0,40)];
		configurationView = pluginView;
		
		[[[self window] contentView] addSubview: pluginView];
		[FSTypePopup setNextKeyView: pluginView];

		// resize window
		NSRect old = initialRect;
		float shift = [pluginView frame].size.height - 20;
		NSRect new = NSMakeRect(old.origin.x, old.origin.y-shift, old.size.width,
							   old.size.height+shift);
		[[self window] setFrame: new display:YES animate: YES];
		
		previousFSType = [[FSTypePopup selectedItem] title];
	}
	else if ([[FSTypePopup selectedItem] title] == selectTypeMenuItemName)
	{
		[self clear];
	}
}

- (BOOL)windowShouldClose:(NSNotification*)note
{
	if (fileSystem == nil)
		return YES;
	
	if (mode == FavoriteEditMode)
	{
		NSString* error;
		BOOL validFS = [fsUIController validateFilesystem:&error];
		if (validFS)
		{
			return true;
		}
		else
		{
			[[NSAlert alertWithMessageText:error defaultButton:@"OK" 
						   alternateButton:nil otherButton:nil informativeTextWithFormat:@""] runModal];
			return false;
		}
	}
	if (mode == FavoriteAddMode || mode == QuickMountMode)
	{
		return true;
	}
	
	return true;
}

- (IBAction)endButtonClicked:(id)sender
{
	NSString* error;
	
	BOOL pluginValidate = [fsUIController validateFilesystem:&error];
	BOOL mainControllerValidate = [mainController validateFilesystem:fileSystem
															   error:&error];
	
	[fsUIController commitEdits];
	if (fileSystem == nil)
		return;
	
	if (pluginValidate == YES && mainControllerValidate == YES)
	{
		if (mode == FavoriteEditMode)
		{
			[[self window] close];
		}
		if (mode == FavoriteAddMode)
		{
			[mainController addFilesystemToFavorites: fileSystem];
			[mainController mountFilesystem: fileSystem];
			[[self window] close];
		}
		if (mode == QuickMountMode)
		{
			[mainController mountFilesystem: fileSystem ];
			if ([switchButton state] == YES)
				[mainController addFilesystemToFavorites: fileSystem];
			[[self window] close];
		}
	}
	else
	{
		[[NSAlert alertWithMessageText:error defaultButton:@"OK" 
					   alternateButton:nil otherButton:nil informativeTextWithFormat:@""] runModal];
	}

}

- (id <FuseFSProtocol>)fileSystem
{
	return fileSystem;
}

- (void) dealloc {
	[fsUIController release];
	[super dealloc];
}

@end
