//
//  SSHFS.m
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

#import "SSHFS.h"
#include <stdlib.h>
#include <stdio.h>
#import "MacFusionConstants.h"
#import "MFLoggingController.h"
#include "signal.h"

@implementation SSHFS

#pragma mark URL Handling methods
+ (BOOL) canHandleURL:(NSURL*)url
{
	return [[url scheme] isEqualTo:@"sftp"];
}

#pragma mark Birth and Death
- (id)initWithURL:(NSURL*)url
{
	self = [super initWithURL:url];
	if ( self != nil ) {
		[self setPort: 22];
		[self setAuthenticationType: SSHFSAuthenticationTypePassword];
		[self setAdvancedOptions:@""];
	}
	return self;
}

- (void) dealloc 
{
	[advancedOptions release];
	[super dealloc];
}


#pragma mark Accessors

- (int)authenticationType
{
	return authenticationType;
}

- (int)port
{
	return port;
}

- (NSString*)advancedOptions
{
	return (advancedOptions ? advancedOptions : @"");
}

- (void)setAuthenticationType:(int)i
{
	authenticationType = i;
}

- (void)setPort:(int)i
{
	port = i;
}

- (void)setAdvancedOptions:(NSString*)s
{
	[advancedOptions release];
	advancedOptions = [s copy];
}

# pragma mark Superclass methods to override

- (NSTask *)filesystemTask
{
	NSTask* t = [[[NSTask alloc] init] autorelease];
	NSMutableArray* arguments = [NSMutableArray array];
	NSString* myPath;
	
	// if no path is specified, give it "" and it will use the user's home
	if ( [self path] != nil)
		myPath = [self path];
	else
		myPath = @"";
	
	// set up the other arguments
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@", [self login], [self hostName], myPath]]; //login@host:path argument
	[arguments addObject: [self mountPath]];
	[arguments addObject: [NSString stringWithFormat:@"-p%d", [self port]]];
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	[arguments addObject: @"-f"];
	//[arguments addObject: @"-vv"];
	
	if (authenticationType == SSHFSAuthenticationTypePassword)
	{
		[arguments addObject: @"-oPasswordAuthentication=yes"];
		[arguments addObject: @"-oPubkeyAuthentication=no"];
	}
	else if (authenticationType == SSHFSAuthenticationTypePublicKey)
	{
		[arguments addObject: @"-oPasswordAuthentication=no"];
		[arguments addObject: @"-oPubkeyAuthentication=yes"];
	}
	
	// add our advanced options, add more error handling here later 
	// (what if options are duplicates?)
	if (![advancedOptions isEqualToString:@""])
	{
		NSArray* extraArguments = [advancedOptions componentsSeparatedByString:@" "];
		NSEnumerator* e = [extraArguments objectEnumerator];
		NSString* extraArg;
		while(extraArg = [e nextObject])
			[arguments addObject:extraArg];
	}
	
	MacFusionController* mainController = [[NSApplication sharedApplication] delegate];
	if ([[mainController getMacFuseVersion] isEqualToString:@"0.4.0"])
	{
		[arguments addObject:[NSString stringWithFormat: @"-ovolicon=%@", [self iconPath]]];
	}
	
	[arguments addObject: @"-oreconnect"];
	[arguments addObject: [NSString stringWithFormat:@"-ovolname=%@", name]]; // volume name argument
	[arguments addObject:@"-oping_diskarb"];
	
	[t setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"sshfs-static" ofType:nil]];
	[t setArguments:arguments];
	
	// set up our environment ... use the app's environment and modify path
	NSBundle* myBundle = [NSBundle bundleForClass: [self class]];
	NSString* askpassPath = [myBundle pathForResource: @"askpass" ofType:@""];
	
	NSMutableDictionary *env = [NSMutableDictionary dictionary];
	[env setObject: askpassPath forKey:@"SSH_ASKPASS"];
	[env setObject: @"NONE" forKey:@"DISPLAY"];
	[env setObject: login forKey:@"SSHFS_USER"];
	[env setObject: hostName forKey:@"SSHFS_SERVER"];
	[t setEnvironment: env];
	
	return t;
}


- (NSDictionary*)dictionaryForSaving
{
	NSMutableDictionary *base = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryForSaving]];
	NSArray* keyNames = [NSArray arrayWithObjects:@"authenticationType", @"port", @"advancedOptions", nil];
	NSDictionary *extra = [self dictionaryWithValuesForKeys:keyNames];
	[base addEntriesFromDictionary:extra];
	return [[base copy] autorelease];
}



- (id)initWithDictionary:(NSDictionary*)dic
{
	self = [super initWithDictionary:dic];
	[self setAuthenticationType: [[dic objectForKey:@"authenticationType"] intValue]];
	[self setPort: [[dic objectForKey:@"port"] intValue]];
	if ([dic objectForKey:@"advancedOptions"])
		[self setAdvancedOptions:[dic objectForKey:@"advancedOptions"]];
	return self;
}


@end
