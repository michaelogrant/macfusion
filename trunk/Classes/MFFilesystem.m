//
//  MacFusionFileSystem.m
//  MacFusion
//
//  Created by Charles Parnot on 6/4/07.
//

#import "MacFusionConstants.h"
#import "MFLoggingController.h"

#import "MFFilesystem.h"

@implementation MFFilesystem

//designated initializer
//subclasses do not need to implement init, which is simply calling initWithURL with empty string
- (id) init
{
	self = [super init];
	if (self != nil)
	{
		//the name is what is displayed to user, hostanme is remote server (if any)
		[self setName:@""];
		[self setMountOnStartup:NO];
		[self setStatus:FuseFSStatusUnmounted];
		[self setIconPath: @""];
		[self setAdvancedOptions:@""];
		[self setIconPath: [self defaultIconPath]];
	}
	return self;
}

- (id) initWithURL:(NSURL*)url
{
	return [self init];
}

//using [self class] ensures that it works fine for subclasses
- (id)copyWithZone:(NSZone *)zone
{
	id newCopy = [[[self class] allocWithZone: zone] initWithDictionary: [self dictionaryForSaving]];
	[newCopy setStatus: [self status]];
	return newCopy;
}

- (void) dealloc 
{
	[name release];
	[task release];
	[outputPipe release];
	[inputPipe release];
	[iconPath release];
	[advancedOptions release];
	[super dealloc];
}


#pragma mark Save/Load from Defaults Methods


- (NSDictionary*)dictionaryForSaving
{
	NSMutableDictionary* d = [NSMutableDictionary dictionary];
	NSArray* keys = [self keysForSaving];
	NSEnumerator* e = [keys objectEnumerator];
	NSString* currentKey;
	
	while(currentKey = [e nextObject])
	{
		if ([[self valueForKey:@"iconPath"] isEqualTo: [self defaultIconPath]] &&
			[currentKey isEqualTo:@"iconPath"])
			continue; // don't save default icon path
		
		if ([self valueForKey:currentKey] != nil)
		{
			[d setObject:[self valueForKey:currentKey] forKey:currentKey];
		}
		else
		{
			// Don't store the value since it's nil
		}
	}
	return [[d copy] autorelease];	
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	if (self = [self init])
	{
		[self setValuesForKeysWithDictionary:dic];
	}
	return self;
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

- (NSArray*)keysForSaving
{
	NSMutableArray* storedKeys = [NSMutableArray array];
	NSArray* keyNames = [NSArray arrayWithObjects:@"name", @"mountOnStartup", @"iconPath", 
		@"advancedOptions", nil];
	[storedKeys addObjectsFromArray:keyNames];
	return [[storedKeys copy] autorelease];	
}

# pragma mark Getters

- (NSString*)name
{
	return name;
}

- (int)status
{
	return status;
}


- (NSString*)iconPath
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:iconPath])
		return iconPath;
	else // icon path invalid
	{
		[self setIconPath: [self defaultIconPath]];
		return iconPath;
	}
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

- (NSString*)recentOutput
{
	return recentOutput;
}

- (NSString*)advancedOptions
{
	return advancedOptions;
}

//appends FS to the fsLongType
- (NSString*)fsType
{
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"FSType"];
}

//using the class name
- (NSString*)fsLongType
{
	NSString *fromTheBundle = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"FSLongType"];
	if ( fromTheBundle == nil )
		return [self fsType];
	else
		return fromTheBundle;
}

- (NSString*)defaultIconPath
{
	return [[NSBundle bundleForClass:[self class]] pathForImageResource:[self fsType]];
}

- (NSImage*)icon
{
	NSImage* icon = [[[NSImage alloc] initWithContentsOfFile:iconPath] autorelease];
	if (icon)
		return icon;
	else // bad icon path
	{
		[self setIconPath: [self defaultIconPath]];
		icon = [[[NSImage alloc] initWithContentsOfFile:iconPath] autorelease];
		return icon;
	}
}

- (NSString*)fsDescription
{
	return [self name];
}

#pragma mark Setters

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
	[aString retain];
	[name release];
	name = aString;
}

- (void)setIconPath:(NSString*)aString
{
	if (aString != nil)
	{
		[aString retain];
		[iconPath release];
		iconPath = aString;
	}
}

- (void)setAdvancedOptions:(NSString*)aString
{
	[aString retain];
	[advancedOptions release];
	advancedOptions = aString;
}


# pragma mark Misc

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

+ (BOOL)canHandleURL:(NSURL*)url
{
	return NO;
}

# pragma mark Mount/Unmount Methods
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


//placeholder for the method that subclasses should implement
- (NSTask *)filesystemTask
{
	if ( [self isMemberOfClass:[MFFilesystem class]] )
		[NSException raise:@"MacFusionFileSystemError" format:@"Instances of MacFusionFileSystem should not be instantiated. Only subclasses may be instantiated."];
	else
		[NSException raise:@"MacFusionFileSystemError" format:@"MacFusionFileSystem subclass '%@' should implement method '%s'", [self class], _cmd];
	return nil;
}

// setup the NSTask to launch the filesystem client
- (NSTask *)setupTaskForMount
{
	//make sure there is a libfuse library in a place where we can find it
	NSString* libfusepath = [self getPathForLibFuse];
	if (libfusepath == nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FuseFSMountFailedNotification object:self userInfo:[NSDictionary dictionaryWithObject:(id)FuseFSMountFaliureLibraryIssue forKey:mountFaliureReasonKeyName]];
		return nil;
	}
	
	//get task from subclass implementation of method 'filesystemTask'
	[task release];
	task = [[self filesystemTask] retain];

	//add the app's environment
	//add env var to make sure the lifuse library is properly linked
	NSMutableDictionary *env;
	if ( [task environment] != nil )
		env = [NSMutableDictionary dictionaryWithDictionary:[task environment]];
	else
		env = [NSMutableDictionary dictionary];
	[env addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
	[env setObject:libfusepath forKey:@"DYLD_LIBRARY_PATH"];
	[task setEnvironment:[[env copy] autorelease]];

	//set up the output pipe
	//outputPipe will be released in the dealloc
	[outputPipe release];
	outputPipe = [[NSPipe alloc] init];
	[inputPipe release];
	inputPipe = [[NSPipe alloc] init];
	[task setStandardError: outputPipe];
	[task setStandardOutput: outputPipe];
	[task setStandardInput: inputPipe];
	
	// register for notification of data coming into the pipe
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleDataOnPipe:) name:NSFileHandleDataAvailableNotification object: [outputPipe fileHandleForReading]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleTaskEnd:) name:NSTaskDidTerminateNotification object: task];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnmountNotification:) name:FuseFSUnmountedNotification object:self];
	
	[[outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
	return task;
}

- (void) handleMountTimeout:(NSTimer*)t
{
	id <FuseFSProtocol> fs = [[t userInfo] objectForKey: filesystemKeyName];
	if ( [fs status] == FuseFSStatusMounted )
		return; // FS mounted OK
	else if ( [fs status] == FuseFSStatusMountFailed ) // already marked as failed (task probably exited): ignore
		return;
	else if ( [fs status] == FuseFSStatusWaitingToMount ) {
		// FS mount failed. Notify.
		[[NSNotificationCenter defaultCenter] postNotificationName: FuseFSMountFailedNotification object:self userInfo:[NSDictionary dictionaryWithObject:(id)FuseFSMountFaliureTimeout forKey:mountFaliureReasonKeyName]];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
	// Really kill the task ... hard!
	kill([task processIdentifier],SIGKILL);
	[self removeMountPoint];
}


- (void)mount
{
	[self setStatus: FuseFSStatusWaitingToMount];
	if ([self setupMountPoint] == YES)
	{
		[self setupTaskForMount];
		
		// set up a timer so we don't have the process hanging and taking forever
		// the timeout is long so that if needed people have a change to enter password
		NSDictionary* timerInfoDic = [NSDictionary dictionaryWithObject: self forKey: filesystemKeyName];
		
		float timeout = [[NSUserDefaults standardUserDefaults] floatForKey: mountTimeoutKeyName];
		[NSTimer scheduledTimerWithTimeInterval:timeout target:self
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

@end
