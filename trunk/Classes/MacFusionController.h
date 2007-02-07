//
//  MacFusionController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MountController.h"
#import <DiskArbitration/DiskArbitration.h>
#import "FuseFSProtocol.h"
#import "../Growl.framework/Headers/GrowlApplicationBridge.h"`
#import "FavoritesController.h"


@class StatusValueTransformer;
@class FavoritesController;
@class MountController;

NSString *ext = @"plugin";
NSString *appSupportSubpath = @"Application Support/MacFusion/PlugIns";

@interface MacFusionController : NSObject <GrowlApplicationBridgeDelegate>
{
	NSStatusItem* statusMenuItem;
	NSMutableArray* favorites;
	NSMutableArray* mounts;
	NSMutableDictionary* plugins;
	MountController* mountController;
	FavoritesController* favoritesController;
	
	DASessionRef appearSession;
	DASessionRef disappearSession;
}

- (void)quickMount:(id)sender;

- (NSMutableArray*)favorites;
- (NSMutableDictionary*)plugins;

- (void)addFilesystemToFavorites:(id <FuseFSProtocol>)fs;
- (void)mountFilesystem:(id <FuseFSProtocol>)fs;
- (void)unmountFilesystem:(id <FuseFSProtocol>)fs;

- (BOOL)validateFilesystem:(id <FuseFSProtocol>)fs error:(NSString**)error;

@end
