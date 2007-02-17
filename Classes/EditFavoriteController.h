//
//  EditFavoriteController.h
//  MacFusion
//
//  Created by Michael Gorbach on 2/13/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacFusionController.h"

@class MacFusionController;


@interface EditFavoriteController : NSWindowController 
{
	MacFusionController* mainController;
	id <FuseFSProtocol> filesystem;
	id <FuseUIProtocol> filesystemUIController;
	id notifyTarget;
}

+ (void) editFavorite:(id <FuseFSProtocol>)favorite onWindow:(id)window notifyTarget: (id)target;

- (id) initWithFavorite:(id <FuseFSProtocol>)favorite;
- (IBAction) okay:(id)sender;
- (IBAction) cancel:(id)sender;

@end
