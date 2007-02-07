//
//  SSHFS.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "SSHFS.h"
#include <stdlib.h>
#include <stdio.h>
#import "../MacFusionConstants.h"

@interface SSHFS (PrivateAPI)
- (NSTask*)setupTaskForMount;
- (NSTask*)setupTaskForUnmount;
- (BOOL)setupMountPoint;
- (void)removeMountPoint;
@end 

@implementation SSHFS

#pragma mark Initialization
- (id) init {
	self = [super init];
	if (self != nil) 
	{
		[self setPingDiskarb:YES];
		[self setLogin: NSUserName()];
		[self setStatus: FuseFSStatusUnmounted];
		[self setAuthenticationType: SSHFSAuthenticationTypePublicKey];
		[self setName: @""];
		[self setPath: @""];
		[self setPort: 22];
		[self setStatus: FuseFSStatusUnmounted];
		[self setMountOnStartup: NO];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleMountFailedNotification:) 
													 name:FuseFSMountFailedNotification object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnmountNotification:) 
													 name:FuseFSUnmountedNotification object:self];
	}
	return self;
}

# pragma mark Mount/Unmount Methods
- (void)mount
{
	[self setStatus: FuseFSStatusWaitingToMount];
	if ([self setupMountPoint] == YES)
	{
		task = [self setupTaskForMount];
		
		// set up a timer so we don't have the process hanging and taking forever
		// the timeout is long so that if needed people have a change to enter password
		NSDictionary* timerInfoDic = [NSDictionary dictionaryWithObject: self 
																 forKey: filesystemKeyName];
		[NSTimer scheduledTimerWithTimeInterval:60.0 target:self
									   selector:@selector(handleMountTimeout:)
									   userInfo:timerInfoDic repeats:NO];
		[task launch];
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

// setup the NSTask to launch the ssh client
// still need to figure out how to do password authentication ...
- (NSTask*)setupTaskForMount
{
	NSTask* t = [[NSTask alloc] init];
	NSMutableArray* arguments = [[NSMutableArray alloc] init];
	NSString* myPath;
	
	// if no path is specified, give it "" and it will use the user's home
	if (path != nil)
		myPath = path;
	else
		myPath = @"";
	
	// set up the other arguments
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@", login, hostName, myPath]]; // login@host:path argument
	[arguments addObject: [self mountPath]];
	[arguments addObject: [NSString stringWithFormat:@"-p%d", port]];
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-f"];
	
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
	
	[arguments addObject: @"-oreconnect"];
	[arguments addObject: [NSString stringWithFormat:@"-ovolname=%@", name]]; // volume name argument

	
	if (pingDiskarb)
		[arguments addObject:@"-oping_diskarb"];
	
	[t setLaunchPath:@"/usr/local/bin/sshfs"];
	[t setArguments:arguments];
	
	// set up our environment ... use the app's environment and modify path
	NSMutableDictionary* env = [NSMutableDictionary dictionaryWithDictionary: 
		[[NSProcessInfo processInfo] environment]];
	NSBundle* myBundle = [NSBundle bundleForClass: [self class]];
	NSString* askpassPath = [myBundle pathForResource: @"askpass" ofType:@""];
	
	[env setObject: askpassPath forKey:@"SSH_ASKPASS"];
	[env setObject: @"NONE" forKey:@"DISPLAY"];
	[env setObject: login forKey:@"SSHFS_USER"];
	[env setObject: hostName forKey:@"SSHFS_SERVER"];
	
	NSString* newPath = [NSString stringWithFormat: @"%@:%@", [env objectForKey:@"PATH"], 
		@"/usr/local/sbin:/usr/local/bin"];
	
	[env setObject:newPath forKey:@"PATH"];
	[t setEnvironment: env];
	
	// set up the output pipe
	if (outputPipe) 
		[outputPipe release];
	outputPipe = [[NSPipe alloc] init];
	[t setStandardError: outputPipe];
	[t setStandardOutput: outputPipe];
	
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
	errorString = [[NSString alloc] initWithData: pipeData encoding:NSASCIIStringEncoding];
}

- (void)handleTaskEnd:(NSNotification*)note
{
	if (status == FuseFSStatusMountFailed) // task died, but mount had already timed out: ignore
	{
		return;
	}
	if (status == FuseFSStatusWaitingToMount) // task died while waiting to mount: notify of faliure
	{
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

// This sets up the mountpoint in ~
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

#pragma mark Save/Load from Defaults Methods
- (id)storageObjectForDefaults
{
	NSArray* keyNames = [NSArray arrayWithObjects: @"name", @"hostName", @"login",
		@"mountPath", @"path", @"authenticationType", @"port", @"mountOnStartup", nil];
	NSDictionary* d = [self dictionaryWithValuesForKeys: keyNames];
	return d;
}

- (id)initWithStoredObject:(id)stored
{
	NSDictionary* myDict = (NSDictionary*)stored;
	[self init];
	[self setName: [myDict objectForKey: @"name"]];
	[self setHostName: [myDict objectForKey: @"hostName"]];
	[self setLogin: [myDict objectForKey: @"login"]];
	[self setPath: [myDict objectForKey:@"path"]];
	[self setAuthenticationType: [[myDict objectForKey:@"authenticationType"]
		intValue]];
	[self setMountOnStartup: [[myDict objectForKey:@"mountOnStartup"] boolValue]];
	[self setPort: [[myDict objectForKey:@"port"] intValue]];
	return self;
}

#pragma mark Accessors

- (NSString*)name
{
	return name;
}

- (NSString*)fsType
{
	return @"SSHFS";
}

- (NSString*)fsLongType
{
	return @"Secure Shell";
}

- (NSString*)fsDescription
{
	if ([[self login] isEqualTo: NSUserName()])
		return [NSString stringWithFormat:@"%@%@",
			[self hostName], [self path]];
	else
		return [NSString stringWithFormat:@"%@\@%@%@",
			[self login], [self hostName], [self path]];
}

- (int)status
{
	return status;
}

- (BOOL)pingDiskarb
{
	return pingDiskarb;
}

- (NSString*)hostName
{
	return hostName;
}

- (BOOL)mountOnStartup
{
	return mountOnStartup;
}

- (NSString*)login
{
	return login;
}

- (NSString*)path
{
	return path;
}

- (NSString*)mountPath
{
	return [NSString stringWithFormat: @"/Volumes/%@", name];
}

- (NSString*)errorString
{
	return errorString;
}

- (int)authenticationType
{
	return authenticationType;
}

- (int)port
{
	return port;
}

- (NSString*)longStatus
{
	if (status == FuseFSStatusMounted)
		return @"Mounted";
	if (status == FuseFSStatusMountFailed)
		return @"Mount Failed";
	if (status == FuseFSStatusUnmounted)
		return @"Unmounted";
	return @"Unkown";
}

# pragma mark Setters
- (void)setName:(NSString*) s
{
	[s copy];
	[name release];
	name = s;
}

- (void)setStatus:(int)s
{
	[self willChangeValueForKey:@"longStatus"];
	status = s;
	[self didChangeValueForKey: @"longStatus"];
}

- (void)setPingDiskarb:(BOOL)yn
{
	pingDiskarb = yn;
}

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
	[s copy];
	[path release];
	path = s;
}

- (void)setAuthenticationType:(int)i
{
	authenticationType = i;
}

- (void)setPort:(int)i
{
	port = i;
}

- (void)setMountOnStartup:(BOOL)yn
{
	mountOnStartup = yn;
}

- (void) dealloc 
{
	[task release];
	[name release];
	[hostName release];
	[path release];
	[login release];
	[super dealloc];
}

@end
