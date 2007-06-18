//
//  MacFusionNetworkFS.h
//  MacFusion
//
//  Created by Michael Gorbach on 6/9/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFileSystem.h"


@interface MFNetworkFS : MFFilesystem {
	//specific for remote access
	NSString* hostName;
	NSString* login;
	NSString* path;
	int port;
}

// Setters
- (void)setHostName:(NSString*)s;
- (void)setLogin:(NSString*)s;
- (void)setPath:(NSString*)s;
- (void)setPort:(int)aPort;

// Getters
- (NSString*)hostName;
- (NSString*)login;
- (NSString*)path;
- (int)port;

@end
