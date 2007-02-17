//
//  EditFavoriteController.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/13/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "EditFavoriteController.h"


@implementation EditFavoriteController
+ (void) editFavorite:(id <FuseFSProtocol>)favorite onWindow:(id)parent notifyTarget:(id)target
{
	EditFavoriteController* editController = [[EditFavoriteController alloc] initWithFavorite: favorite
																				 notifyTarget: target];
	if (parent)
	{
		[[NSApplication sharedApplication] beginSheet: [editController window] modalForWindow: parent 
										modalDelegate:editController didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
										  contextInfo:nil];
	}
	else
	{
		[editController showWindow: nil];
	}
}

- (id) initWithFavorite:(id <FuseFSProtocol>)fs notifyTarget: (id)target
{
	mainController = [[NSApplication sharedApplication] delegate];
	filesystem = fs;
	[super initWithWindowNibName: @"EditFavorites"];
	notifyTarget = target;
	return self;
}

- (void) windowDidLoad
{
	[[self window] setTitle: [NSString stringWithFormat: @"Editing %@", [filesystem name]]];
	// load the correct classes and instantiate
	NSBundle* fsBundle = [[mainController plugins] objectForKey: [filesystem fsType]];
	Class filesystemUIControllerClass = [fsBundle classNamed: 
		[[fsBundle infoDictionary] objectForKey: @"UIClassName"]];
	filesystemUIController = [[filesystemUIControllerClass alloc] initWithFS: 
		filesystem];
	
	// show the view we just loaded
	NSView* pluginView = [filesystemUIController configurationView];
	[pluginView setFrameOrigin: NSMakePoint( 0, 40)];
	[[[self window] contentView] addSubview: pluginView];
	
	// resize window
	NSRect old = [[self window] frame];
	float shift = [pluginView frame].size.height;
	NSRect new = NSMakeRect(old.origin.x, old.origin.y-shift, old.size.width,
							shift + 100);
	[[self window] setFrame: new display:YES animate: YES];
}

- (IBAction) okay:(id)sender
{
	NSString* error;
	
	BOOL pluginValidate = [filesystemUIController validateFilesystem:&error];
	BOOL mainControllerValidate = [mainController validateFilesystem:filesystem
															   error:&error];
	if (pluginValidate && mainControllerValidate)
	{
		if ([[self window] isSheet])
			[[NSApplication sharedApplication] endSheet: [self window]];
		[[self window] close];
		[notifyTarget editCompleteForFavorite: filesystem WithSuccess: YES];
	}
	else
	{
		[[NSAlert alertWithMessageText:error defaultButton:@"OK" 
					   alternateButton:nil otherButton:nil informativeTextWithFormat:@""] runModal];
	}
}

- (IBAction) cancel:(id)sender
{
	if ([[self window] isSheet])
		[[NSApplication sharedApplication] endSheet: [self window]];
	[[self window] close];
	[notifyTarget editCompleteForFavorite: filesystem WithSuccess: NO];
	
}

- (void)windowWillClose:(id)sender
{
	[self autorelease];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

- (void) dealloc 
{
	[super dealloc];
}

@end
