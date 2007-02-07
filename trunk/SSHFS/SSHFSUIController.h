//
//  SSHFSUIController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/15/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../Protocols/FuseUIProtocol.h"
#import "SSHFS.h"

@interface SSHFSUIController : NSObject <FuseUIProtocol>
{
	SSHFS* fileSystem;
	IBOutlet NSView* configurationView;
	NSObjectController* fsController;
}

@end
