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

- (id) initWithURL:(NSURL*)url
{
	self = [self init];
	if (self != nil)
	{
		[self setName: [url host]];
		if ([url user] != nil)
			[self setLogin: [url user]];
		if ([url path] != nil)
			[self setPath: [url path]];
		[self setHostName: [url host]];
	}
	return self;
}

#pragma mark Initialization
- (id) init 
{
	self = [super init];
	if (self != nil) 
	{
		[self setStatus: FuseFSStatusUnmounted];
		[self setName: @""];
		[self setMountOnStartup: NO];
		[self setPath:@""];
		[self setLogin:@""];
		[self setAdvancedOptions:@""];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	FTPFS* newCopy = [[FTPFS allocWithZone: zone] initWithDictionary: [self dictionaryForSaving]];
	[newCopy setStatus: [self status]];
	return newCopy;
}


# pragma mark Mount/Unmount Methods
- (void)mount
{
	NSString* password;
	
	[self setStatus: FuseFSStatusWaitingToMount];
	if ([self setupMountPoint] == YES)
	{
		task = [self setupTaskForMount];
		
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

// setup the NSTask to launch curlftpfs
- (NSTask*)setupTaskForMount
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
	
	// register for notification of data comming into the pipe
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleDataOnPipe:) 
											name:NSFileHandleDataAvailableNotification 
											   object: [outputPipe fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleTaskEnd:)
												 name:NSTaskDidTerminateNotification object: task];
	
	[[outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
		
	[arguments release];
	return t;
}

- (void) handleMountTimeout:(NSTimer*)t
{
	id <FuseFSProtocol> fs = [[t userInfo] objectForKey: filesystemKeyName];
	if ([fs status] == FuseFSStatusMounted)
		return; // FS mounted OK
	else if ([fs status] == FuseFSStatusMountFailed) // already marked as failed (task probably exited): ignore
		return;
	else if ([fs status] == FuseFSStatusWaitingToMount)
	{
		// FS mount failed. Notify.
		[[NSNotificationCenter defaultCenter] postNotificationName: FuseFSMountFailedNotification object:self
														  userInfo: [NSDictionary dictionaryWithObject: (id)FuseFSMountFaliureTimeout 
																								forKey:mountFaliureReasonKeyName]];
															  
		[fs setStatus: FuseFSStatusMountFailed];
	}
}

- (void)handleDataOnPipe:(NSNotification*)note
{
	NSData* pipeData = [[note object] availableData];
	
	if ([pipeData length]==0) // pipe is down. we're done!
		return;
	
	if (recentOutput)
		[recentOutput release];
	
	recentOutput = [[NSString alloc] initWithData: pipeData encoding:NSASCIIStringEncoding];
	
	[[MFLoggingController sharedLoggingController] logMessage:recentOutput 
													   ofType:MacFusionLogTypeConsoleOutput 
													   sender:self];
	[[note object] waitForDataInBackgroundAndNotify];
}

- (void)handleTaskEnd:(NSNotification*)note
{
	if (status == FuseFSStatusMountFailed) // task died, but mount had already timed out: ignore
	{
		return;
	}
	if (status == FuseFSStatusWaitingToMount) // task died while waiting to mount: notify of faliure
	{
		[self removeMountPoint];
		[[NSNotificationCenter defaultCenter] postNotificationName:FuseFSMountFailedNotification object:self
														  userInfo: [NSDictionary dictionaryWithObject: (id)FuseFSMountFaliureTaskEnded 
																								forKey: mountFaliureReasonKeyName]];
		[self setStatus: FuseFSStatusMountFailed];
	}
}

- (void)handleMountFailedNotification:(NSNotification*)note
{
	// failed to mount ... kill task if it's still trying to run
	if ([task isRunning])
		[task terminate];
	
	[self removeMountPoint];
}

- (void)handleUnmountNotification:(NSNotification*)note
{
	[self removeMountPoint];
}

#pragma mark Save/Load from Defaults Methods
- (NSDictionary*)dictionaryForSaving
{
	NSArray* keyNames = [NSArray arrayWithObjects: @"name", @"mountOnStartup", @"hostName", @"login",
		@"path", @"advancedOptions", nil];
	NSDictionary* d = [self dictionaryWithValuesForKeys: keyNames];
	return d;	
}

- (NSDictionary*)dictionaryForDisplay
{
	NSArray* keyNames = [NSArray arrayWithObjects: @"fsDescription", @"fsLongType",
		@"status", nil];
	NSMutableDictionary* d = [[self dictionaryWithValuesForKeys: keyNames] 
		mutableCopy];
	[d addEntriesFromDictionary: [self dictionaryForSaving]];
	return [d copy];
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	self = [self init];
	[self setName: [dic objectForKey:@"name"]];
	[self setMountOnStartup: [[dic objectForKey: @"mountOnStartup"] boolValue]];
	[self setHostName: [dic objectForKey: @"hostName"]];
	[self setLogin: [dic objectForKey: @"login"]];
	[self setPath: [dic objectForKey:@"path"]];
	return self;
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

- (NSString*)fsDescription
{
	return [NSString stringWithFormat:@"%@%@",
		[self hostName], [self path]];
}


- (NSString*)hostName
{
	return hostName;
}

- (NSString*)login
{
	return login;
}

- (NSString*)path
{
	return path;
}

- (NSString*)advancedOptions
{
	return advancedOptions;
}

- (NSString*)recentOutput
{
	return recentOutput;
}

# pragma mark Setters

- (void)setHostName:(NSString*)s
{
	[s copy];
	[hostName release];
	hostName = s;
}

- (void)setLogin:(NSString*)s
{
	[s copy];
	[login release];
	login = s;
}

- (void)setPath:(NSString*)s
{
	if(s==nil) 
		s=@"";
	[s copy];
	[path release];
	path = s;
}

- (void)setAdvancedOptions:(NSString*)s
{
	[s copy];
	[advancedOptions release];
	advancedOptions = s;
}


- (NSImage*)icon
{
	return [[[NSImage alloc] initWithContentsOfFile: 
		[[NSBundle bundleForClass: [self class]] pathForResource:@"FTPFS" ofType:@"icns"]]
		autorelease];
}

# pragma mark General FuseFS
# pragma mark Accessors
- (NSString*)name
{
	return name;
}

- (int)status
{
	return status;
}

- (NSString*)mountPath
{
	return [NSString stringWithFormat: @"/Volumes/%@", name];
}

- (NSString*)longStatus
{
	if (status == FuseFSStatusMounted)
		return @"Mounted";
	if (status == FuseFSStatusMountFailed)
		return @"Mount Failed";
	if (status == FuseFSStatusUnmounted)
		return @"Unmounted";
	if (status == FuseFSStatusWaitingToMount)
		return @"Waiting";
	return @"Unknown";
}

- (BOOL)mountOnStartup
{
	return mountOnStartup;
}

# pragma mark Setters
- (void)setMountOnStartup:(BOOL)yn
{
	mountOnStartup = yn;
}

- (void)setStatus:(int)s
{
	[self willChangeValueForKey:@"longStatus"];
	status = s;
	[self didChangeValueForKey: @"longStatus"];
}

- (void)setName:(NSString*)aString
{
	[aString copy];
	[name release];
	name = aString;
}

# pragma mark Mountpoint setup
- (BOOL)setupMountPoint
{
	BOOL pathExists, isDir;
	NSString* mountPath = [self mountPath];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	
	if (pathExists && isDir == YES) // directory already exists
	{
		if ([[fm directoryContentsAtPath:mountPath] count] == 0) // empty directory ... use as mountpoint
			return YES;
		else
			return NO; // directory not empty ... cant mount at this path. fail.
	}
	else if (pathExists && isDir == NO)
	{
		return NO; // a file exists at that path, we shouldn't delete it. fail.
	}
	else if (pathExists == NO)
	{
		// nothing exists. Create the mountpoint, with default attributes
		[fm createDirectoryAtPath:mountPath attributes:nil];
		return YES;
	}
	return NO;
}

- (void)removeMountPoint
{
	BOOL isDir;
	
	// clean up after self by removing the mountpoint, if it exists and is empty
	NSFileManager* fm = [NSFileManager defaultManager]; 
	if ([fm fileExistsAtPath: [self mountPath] isDirectory:&isDir]) // directory exists
	{
		if ([[fm directoryContentsAtPath: [self mountPath]] count] == 0) // and its empty
			[fm removeFileAtPath: [self mountPath] handler:nil];
	}
	

}

#pragma mark Shared Code
// Code to take into account the fact that libfuse may not be in /usr/local/lib
// But may instead be in /opt/local/lib or /sw/lib due to macports or fink
- (NSString*)getPathForLibFuse
{
	NSString* searchPath;
	NSArray* possiblePaths = [NSArray arrayWithObjects:
		@"/usr/local/lib", @"/opt/local/lib", @"/sw/lib", nil];
	NSEnumerator* e = [possiblePaths objectEnumerator];
	while (searchPath = [e nextObject])
	{
		NSString* libraryPath = [searchPath stringByAppendingPathComponent:@"libfuse.0.dylib"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:libraryPath])
			return searchPath; //we've found libfuse!
	}
	
	return nil; // no libfuse ... uh oh
}

- (void) dealloc 
{
	[name release];
	[task release];
	[inputPipe release];
	[outputPipe release];
	[hostName release];
	[path release];
	[login release];
	[advancedOptions release];
	[recentOutput release];
	[super dealloc];
}

@end
