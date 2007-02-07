//
//  QuickMountController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../Protocols/FuseFSProtocol.h"
#import "../Protocols/FuseUIProtocol.h"
#import "MacFusionController.h"

@class MacFusionController;

enum {
	QuickMountReturnOK=1,
	QuickMountReturnCancel=2,
};

enum {
	QuickMountMode=1,
	FavoriteEditMode,
	FavoriteAddMode,
};

NSString* selectTypeMenuItemName = @"Select Type ...";

@interface MountController : NSWindowController 
{
	NSMutableDictionary* plugins;
	
	IBOutlet NSPopUpButton* FSTypePopup;
	IBOutlet NSView* configurationView;
	IBOutlet NSButton* endButton;
	IBOutlet NSButton* switchButton;
	
	id <FuseFSProtocol> fileSystem;
	id <FuseUIProtocol> fsUIController;
	MacFusionController* mainController;
	
	int mode;
	NSString* previousFSType;
	NSRect initialRect;
}

- (IBAction)FSTypeChanged:(id)sender;
- (IBAction)endButtonClicked:(id)sender;
- (void) setForQuickMount;
- (void) setForEditingFavorite: (id <FuseFSProtocol>)fs;
- (void) setForAddingFavorite;
- (void) clear;

- (id <FuseFSProtocol>)fileSystem;

@end
