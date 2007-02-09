//
//  FavoritesController.h
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

#import <Cocoa/Cocoa.h>
#import "MacFusionController.h"
#import "../MacFusionConstants.h"

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
