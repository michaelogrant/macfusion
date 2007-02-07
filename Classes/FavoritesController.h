//
//  FavoritesController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/19/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacFusionController.h"
#import "MacFusionConstants.h"

@class MacFusionController;

@interface FavoritesController : NSWindowController 
{
	NSMutableArray* favorites;
	NSMutableArray* fsControllers;
	MacFusionController* mainController;
	
	IBOutlet NSTableView* tableView;
	IBOutlet NSArrayController* favoritesArrayController;
	IBOutlet NSButton* mountButton;
	IBOutlet NSButton* editButton;
}

- (IBAction) addFavorite:(id)sender;
- (IBAction) removeFavorite:(id)sender;
- (IBAction) modifyFavorite:(id)sender;
- (IBAction) mountButtonClicked:(id)sender;

@end
