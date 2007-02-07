//
//  SSHFS.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../Protocols/FuseFSProtocol.h"
#import "../MacFusionConstants.h"

enum {
	SSHFSAuthenticationTypePassword=0,
	SSHFSAuthenticationTypePublicKey=1,
};

@interface SSHFS : NSObject <FuseFSProtocol>
{
	NSString* name;
	NSString* hostName;
	NSString* login;
	NSString* path;
	BOOL pingDiskarb;
	BOOL mountOnStartup;
	int status;
	int authenticationType;
	int port;
	NSTask* task;
	NSPipe* outputPipe;
	NSString* errorString;
}

// Accessors
- (NSString*)hostName;
- (NSString*)login;
- (NSString*)path;
- (NSString*)mountPath;
- (int)authenticationType;
- (NSString*)errorString;
- (int)port;

// Setters
- (void)setHostName:(NSString*)s;
- (void)setLogin:(NSString*)s;
- (void)setPath:(NSString*)s;
- (void)setAuthenticationType:(int)i;
- (void)setPort:(int)i;

@end
