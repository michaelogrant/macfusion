//
//  MacFusionController.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionController.h"
#import "MacFusionConstants.h"
#import "FavoritesController.h"


@interface MacFusionController (PrivateAPI)
- (void)setUpStatusItem;
- (void)getAllPlugins;
- (NSMutableArray *)allBundles;
- (void)setUpVolumeMonitoring;
- (id <FuseFSProtocol>)findFilesystemForPath:(NSString*)path;
- (void)getFavoritesFromDefaults;
- (void)writeFavoritesToDefaults;
- (void)registerDefaults;
- (void)initializeGrowl;
@end

@implementation MacFusionController

#pragma mark Initialization
- (id) init {
	self = [super init];
	if (self != nil) 
	{
		mounts = [[NSMutableArray alloc] init];
		[self registerDefaults];
		[self getAllPlugins];
		[self getFavoritesFromDefaults];
		[self setUpVolumeMonitoring];
		
		[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(checkAndMountFavorites:)
							  userInfo:nil repeats:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver: self 
												 selector:@selector(handleMountFailedNotification:) 
													 name:FuseFSMountFailedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(handleMountSuccessNotification:)
													 name:FuseFSMountedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(handleUnmountNotification:)
													 name:FuseFSUnmountedNotification object:nil];
		[self initializeGrowl];
			
		[[NSApplication sharedApplication] setDelegate: self];
	}
	return self;
}

- (void)awakeFromNib
{
	[self setUpStatusItem];
}

#pragma mark User Defaults
- (void) registerDefaults
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSArray* emptyFavorites = [[NSMutableDictionary alloc] init];
	NSDictionary* defaultsDic = [NSDictionary dictionaryWithObjectsAndKeys: emptyFavorites,  favoritesKeyName,
		3.0, mountTimeoutKeyName, nil];
	
	[defaults registerDefaults: defaultsDic];
}

// load filesystem model objects from defaults
// in defaults, they are each stored as a dictionary containing the FS type
// as well as the aribtrary object given for storage by the FS plugin
// in this case, the fs plugin is asked for the object to represent it in defaults
- (void) getFavoritesFromDefaults
{
	favorites = [[NSMutableArray alloc] init];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSArray* favoritesFromDefaults = [defaults objectForKey: favoritesKeyName];
	NSEnumerator* favoritesFromDefaultsEnum = [favoritesFromDefaults objectEnumerator];
	id storedFSObject;
	id <FuseFSProtocol> fs;
	NSDictionary* storedFSDict;
	
	// load each favorite item from defaults
	while(storedFSDict = [favoritesFromDefaultsEnum nextObject])
	{
		NSString* FSClassName = [storedFSDict objectForKey: favoritesFSTypeKeyName];
		storedFSObject = [storedFSDict objectForKey: favoritesStoredObjectKeyName];
		Class FSClass = [[plugins objectForKey: FSClassName] principalClass];
		fs = [[FSClass alloc] initWithStoredObject: storedFSObject];
		if (fs != nil)
		{
			[favorites addObject: fs];
			if ([fs status] == FuseFSStatusMounted)
			{
				[mounts addObject: fs];
			}
		}
		else
		{
			NSLog(@"Failed to load favorite of type %@", FSClassName);
		}
	}
}

// write filesystem model objects to defaults
// in defaults, they are each stored as a dictionary containing the FS type
// as well as the arbitrary object for storage by the fs plugin
// in this case, the fs plugin class is asked to provide this storage object
- (void) writeFavoritesToDefaults
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray* favoritesForDefaults = [[NSMutableArray alloc] init];
	NSEnumerator* favoritesEnum = [favorites objectEnumerator];
	id <FuseFSProtocol> fs;
	while(fs = [favoritesEnum nextObject])
	{
		NSDictionary* storedFSDict = [NSDictionary dictionaryWithObjectsAndKeys: 
			[fs fsType], favoritesFSTypeKeyName,
			[fs storageObjectForDefaults], favoritesStoredObjectKeyName, nil];
		[favoritesForDefaults addObject: storedFSDict];
	}
	
	[defaults setObject: [NSArray arrayWithArray: favoritesForDefaults]
				 forKey:favoritesKeyName];
}

// Checks for favorites that were mounted when MacFusion started. Adds these
// to the mounted filesystems. This is fired form a timer, because
// it seems to take a bit for the volumeAppeared callbacks to fire
- (void) checkAndMountFavorites:(NSTimer*)timer
{
	NSEnumerator* favoritesEnum = [favorites objectEnumerator];
	id <FuseFSProtocol> fs;
	while(fs = [favoritesEnum nextObject])
	{
		if ([fs status] == FuseFSStatusMounted)
		{
			[mounts addObject: fs];
		}
		else if ([fs status] == FuseFSStatusUnmounted && [fs mountOnStartup] == YES)
		{
			[self mountFilesystem: fs];
		}
	}
}

#pragma mark Status Item
// method to set up our menu status item
- (void) setUpStatusItem
{
	statusMenuItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 
		NSSquareStatusItemLength];
	
	NSImage* mine = [NSImage imageNamed: @"menuicon.icns"];
	[mine setSize: NSMakeSize(16,16)];
	[statusMenuItem setImage: mine];
	
	NSMenu* myMenu = [[NSMenu alloc] initWithTitle:@"main"];
	[myMenu setDelegate: self];

	[statusMenuItem setMenu: myMenu];
	[statusMenuItem retain];
}

// method for the statusitem menu
// perhaps this could be more optimized?
- (void) menuNeedsUpdate:(NSMenu*)menu
{
	// Clear Previous Menu
	NSEnumerator* mEnum = [[menu itemArray] objectEnumerator];
	NSMenuItem* i;
	while(i = [mEnum nextObject])
		[menu removeItem:i];
	
	// Top Section
	[menu addItemWithTitle:@"Quick Mount ..." action:@selector(quickMount:)
			   keyEquivalent:@""];
	[menu addItemWithTitle:@"Favorites"  action:nil
			   keyEquivalent:@""];
	[[menu itemAtIndex: 0] setTarget: self];
	[[menu itemAtIndex: 1] setTarget: self];
	
	// Favorites submenu
	NSMenu* favoritesSubMenu = [[NSMenu alloc] initWithTitle:@"Favorites"];
	[favoritesSubMenu addItemWithTitle:@"Edit ..." action:@selector(showFavorites:) keyEquivalent:@""];
	if ([favorites count] > 0)
	{
		[favoritesSubMenu addItem: [NSMenuItem separatorItem]];
		[favoritesSubMenu setAutoenablesItems: NO];
		NSEnumerator* favoritesEnum = [favorites objectEnumerator];
		id <FuseFSProtocol> fs;
		while(fs = [favoritesEnum nextObject])
		{
			NSString* title = [NSString stringWithFormat: @"%@ (%@)",
				[fs name], [fs fsLongType]];
			NSMenuItem* item = [[NSMenuItem alloc] initWithTitle: title action:@selector(handleFSClicked:) keyEquivalent:@""];
			[item setRepresentedObject: fs];
			[favoritesSubMenu addItem: item];
			[item release];
		}
	}
	
	[menu setSubmenu:favoritesSubMenu forItem:[menu itemWithTitle:@"Favorites"]];
	
	// List of mounted filesystems
	if ([mounts count] > 0)
	{
		[menu addItem: [NSMenuItem separatorItem]];
		NSEnumerator* mountEnum = [mounts objectEnumerator];
		id <FuseFSProtocol, NSObject> fs;
		while(fs = [mountEnum nextObject])
		{
			if ([fs status] == FuseFSStatusMounted)
			{
				NSString* title = [NSString stringWithFormat: @"%@ (%@)", 
					[fs name], [fs fsLongType]];
				NSMenuItem* item = [[NSMenuItem alloc] initWithTitle: title action:@selector(handleFSClicked:) keyEquivalent:@""];
				[item setRepresentedObject: fs];
				[menu addItem: item];
				[item release];
			}
		}
	}
	
	[menu addItem: [NSMenuItem separatorItem]];
	[menu setAutoenablesItems: NO];
	[menu addItemWithTitle:@"Preferences ..." action:@selector(showPreferences) keyEquivalent:@""];
	[menu addItemWithTitle:@"Quit MacFusion" action:@selector(quit) keyEquivalent:@""];
}

- (void) handleFSClicked:(NSMenuItem*)sender
{
	id <FuseFSProtocol> fs = [sender representedObject];
	
	if ([fs status] == FuseFSStatusUnmounted)
	{
		[self mountFilesystem: fs];
	}
	else if ([fs status] == FuseFSStatusMounted)
	{
		[[NSWorkspace sharedWorkspace] selectFile: nil inFileViewerRootedAtPath: [fs mountPath]];
	}
}

- (void) quit
{
	[[NSApplication sharedApplication] terminate: self];
}



#pragma mark Important Mount/Unmount methods
- (void) mountFilesystem:(id <FuseFSProtocol>)fs
{
	[mounts addObject: fs];
	[fs mount];
}

- (void) handleMountFailedNotification:(NSNotification*)note
{
	id <FuseFSProtocol> fs = [note object];
	NSString* faliureReason = [[note userInfo] objectForKey: mountFaliureReasonKeyName];
	
	NSString* description;
	
	if ([fs errorString])
		description = [NSString stringWithFormat: @"MacFusion Failed to Mount %@: %@", [fs name],
			[fs errorString]];
	else
	{
		description = [NSString stringWithFormat: @"MacFusion Failed to Mount %@: %@", [fs name],
			faliureReason];
	}
		
	
	[GrowlApplicationBridge notifyWithTitle:@"Mount Failed" description:description
						   notificationName:growlFSMountFailedNotification 
								   iconData:nil priority:0 isSticky:NO clickContext:nil];
	
	[mounts removeObject: fs];
}

- (void) handleMountSuccessNotification:(NSNotification*)note
{
	id <FuseFSProtocol> fs = [note object];
	
	NSString* description = [NSString stringWithFormat: @"MacFusion successfully mounted %@", [fs name]];
	[GrowlApplicationBridge notifyWithTitle: @"Mount Successful" description:description 
						   notificationName:growlFSMountSuccessNotification 
								   iconData:nil priority:0 isSticky:NO clickContext:nil];
}

- (void) handleUnmountNotification:(NSNotification*)note
{
	id <FuseFSProtocol> fs = [note object];
	[mounts removeObject: fs];
}

#pragma mark Action Methods
// quick mount a fileSystem
- (void) quickMount:(id)sender
{
	if (mountController == nil)
		mountController = [[MountController alloc] init];
	[mountController setForQuickMount];
}

- (void) showFavorites:(id)sender
{
	if (favoritesController == nil)
		favoritesController = [[FavoritesController alloc] init];
	[[favoritesController window] makeKeyAndOrderFront: self];
}

#pragma mark Methods for Controllers
- (void)quickMountFilesystem:(id <FuseFSProtocol>)fs 
			  addToFavorites:(BOOL)favorite
{
	[self mountFilesystem: fs];
	if (favorite)
	{
		[favorites addObject: fs];
	}
}

- (void)addFilesystemToFavorites:(id <FuseFSProtocol>)fs
{
	NSIndexSet* mySet = [NSIndexSet indexSetWithIndex: [favorites count]];
	[self willChange: NSKeyValueChangeInsertion valuesAtIndexes:mySet forKey:@"favorites"];
	[favorites addObject: fs];
	[self didChange: NSKeyValueChangeInsertion valuesAtIndexes:mySet  forKey:@"favorites"];
}

- (BOOL)validateFilesystem:(id <FuseFSProtocol>)newfs
					 error:(NSString**)error;
{
	NSEnumerator* favEnum = [favorites objectEnumerator];
	NSEnumerator* mountsEnum = [mounts objectEnumerator];
	id <FuseFSProtocol> existingfs;
	while (existingfs = [favEnum nextObject])
	{
		if ([[existingfs name] isEqualTo: [newfs name]] && newfs != existingfs)
		{
			*error = @"Name already exists";
			return NO;
		}
	}
	while (existingfs = [mountsEnum nextObject])
	{
		if ([[existingfs name] isEqualTo: [newfs name]])
		{
			*error = @"Name already exists";
			return NO;
		}
	}
	return YES;
}

- (void)unmountFilesystem:(id <FuseFSProtocol>)fs
{
	if ([fs status] == FuseFSStatusMounted)
	{
		int status;
		NSTask* unmountTask = [[NSTask alloc] init];
		[unmountTask setArguments: [NSArray arrayWithObject: [fs mountPath]]];
		[unmountTask setLaunchPath:@"/sbin/umount"];
		[unmountTask launch];
		[unmountTask waitUntilExit];;
		status = [unmountTask terminationStatus];
		if (status != 0)
		{
			NSString* description = [NSString stringWithFormat:@"MacFusion Failed to Unmount %@", [fs name]];
			[GrowlApplicationBridge notifyWithTitle: @"Unmount Failed" description:description 
								   notificationName:growlFSUnmountFailedNotification 
										   iconData:nil priority:0 isSticky:NO clickContext:nil];
		}
	}
}

#pragma mark Plugin Loading
// method to load all plugins from bundles
- (void)getAllPlugins
{
	NSMutableArray* allBundlePaths = [self allBundles];
	NSEnumerator* e = [allBundlePaths objectEnumerator];
	NSString* path;
	plugins = [[NSMutableDictionary alloc] init];
	while(path = [e nextObject])
	{
		NSBundle* b = [NSBundle bundleWithPath:path];
		NSString* fsType = [[b infoDictionary] objectForKey:@"FSType"];
		[plugins setObject: b forKey: fsType];
		[b load];
		NSLog(@"Loaded %@ filesystem from %@", fsType, 
			  [[b infoDictionary] objectForKey: @"CFBundleIdentifier"]);
	}
}

// method to find all bundles that we can load as plugins
// searches inside main bundle and also in a subdir of ~/Application Support
- (NSMutableArray *)allBundles
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
	
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
							NSAllDomainsMask - NSSystemDomainMask, YES);
	
    searchPathEnum = [librarySearchPaths objectEnumerator];
	
    while(currPath = [searchPathEnum nextObject])
    {
        [bundleSearchPaths addObject:
			[currPath stringByAppendingPathComponent:appSupportSubpath]];
    }
	
    [bundleSearchPaths addObject: 
		[[NSBundle mainBundle] builtInPlugInsPath]];
	
    searchPathEnum = [bundleSearchPaths objectEnumerator];
	
    while(currPath = [searchPathEnum nextObject])
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager]
            enumeratorAtPath:currPath];
		
        if(bundleEnum)
        {
            while(currBundlePath = [bundleEnum nextObject])
            {
                if([[currBundlePath pathExtension] isEqualToString:ext])
                {
					[allBundles addObject:[currPath
                           stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
    return allBundles;
}

#pragma mark Diskarbitration Monitoring
// disk mounted callback: sets status of found filesystem to mounted
static void diskMounted(DADiskRef disk, void* mySelf) 
{
	id <FuseFSProtocol> fs;
	id self = (MacFusionController*)mySelf;
	
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	
	if (pathURL)
	{
		CFStringRef path = CFURLCopyFileSystemPath(pathURL,kCFURLPOSIXPathStyle);
		if (fs = [self findFilesystemForPath:(NSString*)path])
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: FuseFSMountedNotification object:fs
															  userInfo: nil];
			[fs setStatus: FuseFSStatusMounted];
		}
		CFRelease(path);
	}
	
	CFRelease(description);
}

// disk unmounted callback: sets status of the found filesystem to unmounted
static void diskUnMounted(DADiskRef disk, void* mySelf)
{
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	id <FuseFSProtocol> fs;
	id self = (MacFusionController*)mySelf;
	
	if (pathURL)
	{
		CFStringRef path = CFURLCopyFileSystemPath(pathURL,kCFURLPOSIXPathStyle);
		if (fs = [self findFilesystemForPath:(NSString*)path])
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: FuseFSUnmountedNotification object:fs
															  userInfo: nil];
			[fs setStatus: FuseFSStatusUnmounted];
		}
		CFRelease(path);
	}

	CFRelease(description);
}

// function to take a mount path and see if any filesystems we know are associated
// with this path
- (id <FuseFSProtocol>) findFilesystemForPath:(NSString*)path
{
	NSEnumerator* mountsEnum = [mounts objectEnumerator];
	NSEnumerator* favoritesEnum = [favorites objectEnumerator];
	id <FuseFSProtocol> fs;
	while(fs = [mountsEnum nextObject])
	{
		if ([path compare: [fs mountPath]] == NSOrderedSame)
			return fs;
	}
	while(fs = [favoritesEnum nextObject])
	{
		if ([path compare: [fs mountPath]] == NSOrderedSame)
			return fs;
	}
	return nil;
}

// seets up callbacks needed to monitor mounting/unmounting of FUSE volumes
- (void) setUpVolumeMonitoring
{
	appearSession = DASessionCreate(kCFAllocatorDefault);
	disappearSession = DASessionCreate(kCFAllocatorDefault);
	
	DASessionScheduleWithRunLoop(appearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionScheduleWithRunLoop(disappearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	DARegisterDiskAppearedCallback(appearSession, kDADiskDescriptionMatchVolumeMountable, diskMounted, self);
	DARegisterDiskDisappearedCallback(disappearSession, kDADiskDescriptionMatchVolumeMountable, diskUnMounted, self);	
}

#pragma mark Growl Notification Code
- (void) initializeGrowl
{
	[GrowlApplicationBridge setGrowlDelegate: self];
}

- (NSDictionary*) registrationDictionaryForGrowl
{
	NSArray* defaultNotifications = [NSArray arrayWithObjects: growlFSMountFailedNotification, growlFSUnmountFailedNotification,
		nil];
	NSArray* allNotifications = [NSArray arrayWithObjects: growlFSMountFailedNotification,
		growlFSMountSuccessNotification, growlFSUnmountFailedNotification, nil];
	
	NSDictionary* growlRegistration = [NSDictionary dictionaryWithObjectsAndKeys: 
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		allNotifications, GROWL_NOTIFICATIONS_ALL, nil];
	
	return growlRegistration;
}

#pragma mark Accessors
- (NSMutableArray*) favorites
{
	return favorites;
}

- (NSMutableDictionary*) plugins
{
	return plugins;
}

#pragma mark Other

#pragma mark Cleanup Code
- (void) applicationWillTerminate:(NSNotification*)note
{
	[self writeFavoritesToDefaults];
}

- (void) dealloc 
{
	DASessionUnscheduleFromRunLoop(appearSession,CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionUnscheduleFromRunLoop(disappearSession,CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	CFRelease(appearSession);
	CFRelease(disappearSession);
	
	[favorites release];
	[mounts release];
	
	[plugins release];
	[statusMenuItem release];
	[super dealloc];
}

@end
