//
//  FTPFS.m
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

#import "FTPFS.h"
#include <stdlib.h>
#include <stdio.h>
#import "../MacFusionConstants.h"
#import "../Classes/MFLoggingController.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#import "ftp_askpass.h"
#include <unistd.h>

@interface FTPFS (PrivateAPI)
- (NSTask*)setupTaskForMount;
- (NSTask*)setupTaskForUnmount;
@end 

@implementation FTPFS
#pragma mark URL opening Methods
+ (BOOL) canHandleURL:(NSURL*)url
{
	return [[url scheme] isEqualTo:@"ftp"];
}

#pragma mark Initialization
- (id) init 
{
	self = [super init];
	if (self != nil) 
	{
		[self setLogin:nil];
		[self setPort:21];
	}
	return self;
}

// setup the NSTask to launch curlftpfs
- (NSTask *)filesystemTask
{
	NSTask* t = [[NSTask alloc] init];
	NSMutableArray* arguments = [[NSMutableArray alloc] init];
	NSString* myPath;
	NSDictionary* env;
	
	// if no path is specified, give it "" and it will use the user's home
	if (path != nil)
		myPath = path;
	else
		myPath = @"";
	
	// find our library
	NSString* libfusepath = [self getPathForLibFuse];
	if (libfusepath == nil)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:FuseFSMountFailedNotification object:self
														  userInfo:[NSDictionary dictionaryWithObject:(id)FuseFSMountFaliureLibraryIssue 
																							   forKey:mountFaliureReasonKeyName]];
		return nil;
	}
	else
	{
		env = [NSDictionary dictionaryWithObjectsAndKeys: libfusepath, @"DYLD_LIBRARY_PATH", nil];
	}
	
	// set up the other arguments
	[arguments addObject: [NSString stringWithFormat:@"%@%@", hostName, myPath]]; // login@host:path argument
	[arguments addObject: [self mountPath]];
	[arguments addObject: @"-f"];
	
	if ([self login] == nil || [[self login] isEqualTo:@""] || [[self login] isEqualTo:@"anonymous"])
	{
		// anonymous FTP
	}
	else // use a login/pass
	{
		[arguments addObject: [NSString stringWithFormat:@"-ouser=%@", [self login]]];
		usingPassword = YES;
	}
	
	[arguments addObject: [NSString stringWithFormat:@"-odisable_epsv"]];
	[arguments addObject: [NSString stringWithFormat:@"-ovolname=%@", name]]; // volume name argument
	[arguments addObject:@"-oping_diskarb"];
	
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
	if ([mainController macFuseAtLeastVersion:@"0.4.0"])
	{
		[arguments addObject:[NSString stringWithFormat: @"-ovolicon=%@", [self iconPath]]];
	}
	
	// FIXME: Should this be needed?
	[arguments addObject: [NSString stringWithFormat:@"-ouid=%d", getuid()]];
	
	[t setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"curlftpfs-static" ofType:nil]];
	[t setArguments:arguments];
		
	[arguments release];
	return t;
}

- (void)mount
{
	[super mount];
	NSString* password;
	if (usingPassword)
	{
		password = FTPFSGetPasswordForUserAndServer([[self login] cString], [[self hostName] cString]);
		NSString* writeString = [NSString stringWithFormat:@"%@\n", password];
		[[inputPipe fileHandleForWriting] writeData: [writeString dataUsingEncoding:NSASCIIStringEncoding]];
	}
}

#pragma mark Accessors

- (NSString*)fsType
{
	return @"FTPFS";
}

- (NSString*)fsLongType
{
	return @"FTP";
}

# pragma mark Setters

- (void) dealloc 
{
	[super dealloc];
}

@end
