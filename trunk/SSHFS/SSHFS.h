//
//  SSHFS.h
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
#import "../Protocols/FuseFSProtocol.h"
#import "../MacFusionConstants.h"

@class FuseFSGeneral;

enum {
	SSHFSAuthenticationTypePassword=0,
	SSHFSAuthenticationTypePublicKey=1,
};

@interface SSHFS : NSObject <FuseFSProtocol>
{
	// General FuseFS Code
	NSString* name;
	BOOL mountOnStartup;
	int status;
	
	// SSHFS Specific
	NSString* hostName;
	NSString* login;
	NSString* path;
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
- (int)authenticationType;
- (NSString*)errorString;
- (int)port;

// Setters
- (void)setHostName:(NSString*)s;
- (void)setLogin:(NSString*)s;
- (void)setPath:(NSString*)s;
- (void)setAuthenticationType:(int)i;
- (void)setPort:(int)i;

// General FuseFS Code
- (NSString*)longStatus;
- (BOOL)setupMountPoint;
- (void)removeMountPoint;

@end
