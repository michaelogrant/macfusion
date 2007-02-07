//
//  FuseUIProtocol.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/15/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//
#import "../Protocols/FuseFSProtocol.h"
@protocol FuseUIProtocol <NSObject>

- (NSView*)configurationView; // method to get the created by this plugin for configured the filesystem
- (id <FuseFSProtocol>) fileSystem; // the filesystem object itself
- (BOOL) validateFilesystem:(NSString**)error; // method to confirm that the object is mostly valid and ready to store/try to mount, error passed by ref.
- (void) commitEdits;

- (id) initWithFS:(id <FuseFSProtocol>)fs;
@end
