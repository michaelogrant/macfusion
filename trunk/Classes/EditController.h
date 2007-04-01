//
//  EditFavoriteController.h
//  MacFusion
//
//  Created by Michael Gorbach on 2/13/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacFusionController.h"
#import "InformalProtocols.h"

@class MacFusionController;


@interface EditController : NSWindowController 
{
	MacFusionController* mainController;
	id <FuseFSProtocol> filesystem;
	id <FuseUIProtocol> filesystemUIController;
	id notifyTarget;
	id imageView;
}

+ (void) editFilesystem:(id <FuseFSProtocol>)fs onWindow:(id)window notifyTarget: (id)target;

- (id) initWithFilesystem:(id <FuseFSProtocol>)fs notifyTarget: (id)target;
- (IBAction) okay:(id)sender;
- (IBAction) cancel:(id)sender;

@end
