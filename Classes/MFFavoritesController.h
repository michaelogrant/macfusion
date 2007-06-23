//
//  MFFavoritesController.h
//  MacFusion
//
//  Created by Michael Gorbach on 2/12/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacFusionFSCell.h"
#import "MacFusionStatusCell.h"
#import "EditController.h"
#import "MacFusionActionButton.h"
#import "MacFusionConstants.h"

@class MacFusionController;
@class MacFusionActionButton;

@interface MFFavoritesController : NSWindowController {
	IBOutlet NSTableView* favoritesTableView;
	IBOutlet NSArrayController* favoritesArrayController;
	IBOutlet MacFusionActionButton* addButton;
	IBOutlet NSButton* removeButton;
	IBOutlet NSButton* editButton;
	IBOutlet NSButton* mountButton;
	
	MacFusionController* mainController;
	
	id <FuseFSProtocol> backup;
}

- (IBAction) mountFavorite:(id)sender;
- (IBAction) editFavorite:(id)sender;
- (IBAction) removeFavorite:(id)sender;

@end
