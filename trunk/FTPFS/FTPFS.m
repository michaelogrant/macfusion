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
	if ([[mainController getMacFuseVersion] isEqualToString:@"0.4.0"])
	{
		[arguments addObject:[NSString stringWithFormat: @"-ovolicon=%@", [self iconPath]]];
	}
	
	// FIXME: Should this be needed?
	[arguments addObject: [NSString stringWithFormat:@"-ouid=%d", getuid()]];
	
	[t setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"curlftpfs-static" ofType:nil]];
	[t setArguments:arguments];
	
	// set up the output pipe
	if (outputPipe) 
		[outputPipe release];
	outputPipe = [[NSPipe alloc] init];
	[t setStandardError: outputPipe];
	[t setStandardOutput: outputPipe];
	[t setEnvironment:env];
		
	[arguments release];
	return t;
}

- (void)mount
{
	NSString* password;
	
	[self setStatus: FuseFSStatusWaitingToMount];
	if ([self setupMountPoint] == YES)
	{
		task = [self filesystemTask];
		
		// set up a timer so we don't have the process hanging and taking forever
		// the timeout is long so that if needed people have a change to enter password
		NSDictionary* timerInfoDic = [NSDictionary dictionaryWithObject: self 
																 forKey: filesystemKeyName];
		
		if (usingPassword)
		{
			// get our password and set up or input pipe
			password = FTPFSGetPasswordForUserAndServer([[self login] cString], [[self hostName] cString]);
			if (inputPipe)
				[inputPipe release];
			inputPipe = [[NSPipe alloc] init];
			[task setStandardInput: inputPipe];
		}
		
		float timeout = [[NSUserDefaults standardUserDefaults] floatForKey: mountTimeoutKeyName];
		[NSTimer scheduledTimerWithTimeInterval:timeout target:self
									   selector:@selector(handleMountTimeout:)
									   userInfo:timerInfoDic repeats:NO];
		
		
		[task launch];
		
		if (usingPassword)
		{
			// send the password to the curlftpfs process
			NSString* writeString = [NSString stringWithFormat:@"%@\n", password];
			[[inputPipe fileHandleForWriting] writeData: [writeString dataUsingEncoding:NSASCIIStringEncoding]];
		}
		
	}
	else
	{
		// couldn't create the path ... fail to mount
		[[NSNotificationCenter defaultCenter] postNotificationName:FuseFSMountFailedNotification object:self
														  userInfo:[NSDictionary dictionaryWithObject:(id)FuseFSMountFaliurePathIssue 
																							   forKey:mountFaliureReasonKeyName]];
		[self setStatus: FuseFSStatusMountFailed];
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
