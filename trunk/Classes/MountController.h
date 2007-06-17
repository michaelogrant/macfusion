//
//  QuickMountController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
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

#import <Cocoa/Cocoa.h>
#import "../Protocols/FuseFSProtocol.h"
#import "../Protocols/FuseUIProtocol.h"
#import "MFMainController.h"

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
