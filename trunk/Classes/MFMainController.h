//
//  MFMainController.h
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
#import "MountController.h"
#import <DiskArbitration/DiskArbitration.h>
#import "FuseFSProtocol.h"
#import "../Growl.framework/Headers/GrowlApplicationBridge.h"`
#import "EditController.h"
#import "MFPrefsController.h"
#import "MFLoggingController.h"


@class FancyFavoritesController;
@class EditFavoriteController;
@class MFPrefsController;
@class MFLoggingController;

@interface MacFusionController : NSObject <GrowlApplicationBridgeDelegate>
{
	NSStatusItem* statusMenuItem;
	NSMutableArray* favorites;
	NSMutableArray* mounts;
	NSMutableDictionary* plugins;
	NSMutableArray* sleepMounts;

	FancyFavoritesController* fancyFavoritesController;
	MFPrefsController* preferencesController;
	
	DASessionRef appearSession;
	DASessionRef disappearSession;
}

- (NSMutableDictionary*)plugins;
- (NSMutableArray*)favorites;

- (void)addFilesystemToFavorites:(id <FuseFSProtocol>)fs;
- (void)mountFilesystem:(id <FuseFSProtocol>)fs;
- (int)unmountFilesystem:(id <FuseFSProtocol>)fs;
- (NSMenu*)filesystemTypesMenuWithTarget: (id)target;
- (void)writeFavoritesToDefaults;
- (NSString*)getMacFuseVersion;
- (BOOL)validateFilesystem:(id <FuseFSProtocol>)fs error:(NSString**)error;

- (void) setLoginItemEnabled:(BOOL)enabled;
@end
