//
//  MFMainController.m
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


#import "MFMainController.h"
#import "MacFusionConstants.h"
#import "MFFavoritesController.h"

@interface MacFusionController (PrivateAPI)
- (void)setUpStatusItem;
- (void)getAllPlugins;
- (NSMutableArray *)allBundles;
- (void)setUpVolumeMonitoring;
- (id <FuseFSProtocol>)findFilesystemForPath:(NSString*)path;
- (void)getFavoritesFromDefaults;
- (void)registerDefaults;
- (void)initializeGrowl;
- (void)readDefaults;
- (void)registerURLHandling;
- (void)checkForMacFuse;
@end

@implementation MacFusionController

#pragma mark Initialization
- (id) init {
	self = [super init];
	if (self != nil) 
	{
		[MFLoggingController sharedLoggingController]; // start logging
		mounts = [[NSMutableArray alloc] init];
		nonLoadedFavorites = [[NSMutableArray alloc] init];
		
		[self checkForMacFuse];
		[self registerDefaults];
		[self getAllPlugins];
		[self readDefaults];
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
		
		[self registerURLHandling];
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
		[NSNumber numberWithDouble: 60.0 ], mountTimeoutKeyName, 
		[NSNumber numberWithBool: NO], startOnLoginKeyName,
		[NSNumber numberWithBool: NO], unmountOnSleepKeyName,
		[NSNumber numberWithBool:YES], @"SUCheckAtStartup",
		nil];
	
	[defaults registerDefaults: defaultsDic];
}

- (void) readDefaults
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[self setLoginItemEnabled: [[defaults objectForKey:startOnLoginKeyName] boolValue]];
	int unmountOnSleepValue = [[defaults objectForKey:unmountOnSleepKeyName] intValue];
	
	if (unmountOnSleepValue == UnmountOnSleepNoRemount || 
		unmountOnSleepValue == UnmountOnSleepRemountOnWake)
	{
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleSleepNotification:) 
																   name:NSWorkspaceWillSleepNotification object:nil];
	}
	if (unmountOnSleepValue == UnmountOnSleepRemountOnWake)
	{
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(handleWakeNotification:) 
																   name:NSWorkspaceDidWakeNotification object:nil];
	}
	
	[self getFavoritesFromDefaults];
}

- (void) setLoginItemEnabled:(BOOL)enabled
{
	NSString* myCurrentPath = [[NSBundle mainBundle] bundlePath];
	
	// set up architecture of getting login items
	NSUserDefaults* loginDefaults = [[NSUserDefaults alloc] init];
	NSMutableDictionary* loginDictionary = [[loginDefaults persistentDomainForName: @"loginwindow"] mutableCopy];
	if (!loginDictionary) 
		loginDictionary = [[NSMutableDictionary alloc] init];
	NSMutableArray* startupItems = [[loginDictionary objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy];
	if (!startupItems)
		startupItems = [[NSMutableDictionary alloc] init];
	
	BOOL found = NO;
	NSDictionary *d, *myEntry;
	NSEnumerator* e = [startupItems objectEnumerator];
	while (d = [e nextObject])
	{
		if ([[d objectForKey:@"Path"] isEqualTo: myCurrentPath])
		{
			found = YES;
			myEntry = d;
		}
	}
	
	if (!enabled && found) // delete it
	{
		[startupItems removeObject: myEntry];
	}
	else if (enabled && !found) // add it
	{
		myEntry = [NSDictionary dictionaryWithObjectsAndKeys: myCurrentPath, @"Path",
			[NSNumber numberWithBool: NO], @"Hide", nil];
		[startupItems addObject: myEntry];
	}
	else if (enabled && found)
		return;
	else if (!enabled && !found)
		return;
	
	// actually modify the defaults
	[loginDictionary setObject: startupItems forKey:@"AutoLaunchedApplicationDictionary"];
	[loginDefaults removePersistentDomainForName: @"loginwindow"];
	[loginDefaults setPersistentDomain:loginDictionary forName:@"loginwindow"];
	[loginDefaults synchronize];
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
		fs = [[FSClass alloc] initWithDictionary: storedFSObject];
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
			MFLog(@"Failed to load favorite of type %@", FSClassName);
			[nonLoadedFavorites addObject: storedFSDict];
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
	NSMutableArray* favoritesForDefaults = [NSMutableArray arrayWithArray:nonLoadedFavorites];
	NSEnumerator* favoritesEnum = [favorites objectEnumerator];
	id <FuseFSProtocol> fs;
	while(fs = [favoritesEnum nextObject])
	{
		NSDictionary* storedFSDict = [NSDictionary dictionaryWithObjectsAndKeys: 
			[fs fsType], favoritesFSTypeKeyName,
			[fs dictionaryForSaving], favoritesStoredObjectKeyName, nil];
		[favoritesForDefaults addObject: storedFSDict];
	}
	
	[defaults setObject: [NSArray arrayWithArray: favoritesForDefaults]
				 forKey:favoritesKeyName];
	[defaults synchronize];
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
	
	NSImage* menuIcon = [NSImage imageNamed:@"MacFusion_Menu_Dark.png"];
	NSImage* menuIconSelected = [NSImage imageNamed:@"MacFusion_Menu_Light.png"];
	
	[statusMenuItem setImage: menuIcon];
	[statusMenuItem setAlternateImage: menuIconSelected];
	[statusMenuItem setHighlightMode: YES];
	[statusMenuItem setTarget: self];

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
	[menu addItemWithTitle:@"Quick Mount" action:nil

			   keyEquivalent:@""];
	[menu addItemWithTitle:@"Favorites"  action:nil
			   keyEquivalent:@""];
	
	// Quickmount submenu
	[menu setSubmenu: [self filesystemTypesMenuWithTarget: self] forItem: 
		[menu itemWithTitle:@"Quick Mount"]];
	
	// Favorites submenu
	NSMenu* favoritesSubMenu = [[NSMenu alloc] initWithTitle:@"Favorites"];
	[favoritesSubMenu addItemWithTitle:@"Edit..." action:@selector(showFavorites:) keyEquivalent:@""];
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
	[menu addItemWithTitle:@"Preferences ..." action:@selector(showPreferences:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Log ..." action:@selector(showLog:) keyEquivalent:@""];
	[menu addItemWithTitle:@"About MacFusion"  action:@selector(showAbout:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Quit" action:@selector(quit) keyEquivalent:@""];
}

- (void) handleFSClicked:(NSMenuItem*)sender
{
	id <FuseFSProtocol> fs = [sender representedObject];
	
	if ([fs status] == FuseFSStatusUnmounted || [fs status] == FuseFSStatusMountFailed)
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
	
	if ([fs recentOutput])
		description = [NSString stringWithFormat: @"MacFusion Failed to Mount %@: %@", [fs name],
			[fs recentOutput]];
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

- (void) filesystemTypeChosen:(NSMenuItem*)item
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	Class FSClass = [item representedObject];
	id <FuseFSProtocol> fs = [[FSClass alloc] init];
	[EditController editFilesystem: fs onWindow:nil notifyTarget:self];
}

- (void) editCompleteForFilesystem:(id <FuseFSProtocol>)fs WithSuccess: (BOOL) success
{
	if (success)
	{
		[self mountFilesystem: fs];
	}
	else
		return;
}

- (void) showFavorites:(id)sender
{
	if (MFFavoritesController == nil)
		MFFavoritesController = [[MFFavoritesController alloc] init];
	[[MFFavoritesController window] makeKeyAndOrderFront: self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
}

- (void) showPreferences:(id)sender
{
	if (preferencesController == nil)
	{
		preferencesController = [[MFPrefsController alloc] init];
	}
	
	[preferencesController showWindow: self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
}

- (void) showLog:(id)sender
{
	[[MFLoggingController sharedLoggingController] showWindow:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
}

- (void) showAbout:(id)sender
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
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
	if (![favorites containsObject: fs])
	{
		NSIndexSet* mySet = [NSIndexSet indexSetWithIndex: [favorites count]];
		[self willChange: NSKeyValueChangeInsertion valuesAtIndexes:mySet forKey:@"favorites"];
		[favorites addObject: fs];
		[self didChange: NSKeyValueChangeInsertion valuesAtIndexes:mySet  forKey:@"favorites"];
	}
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
			*error = @"Name already exists in Favorites";
			return NO;
		}
	}
	while (existingfs = [mountsEnum nextObject])
	{
		if ([[existingfs name] isEqualTo: [newfs name]] && newfs != existingfs)
		{
			*error = @"Name already exists in Mounts";
			return NO;
		}
	}
	return YES;
}

- (int)unmountFilesystem:(id <FuseFSProtocol>)fs
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
										   iconData:nil priority:0 isSticky:YES clickContext:nil];
		}
		return status;
	}
	
	return -1;
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
		if ([[b principalClass] conformsToProtocol: @protocol(FuseFSProtocol)])
		{
			NSString* fsType = [[b infoDictionary] objectForKey:@"FSType"];
			[plugins setObject: b forKey: fsType];
			[b load];
			MFLog(@"Loaded %@ filesystem from %@", fsType, 
				  [[b infoDictionary] objectForKey: @"CFBundleIdentifier"]);
		}
		else
		{
			MFLog(@"Not loading bundle %@", [[b infoDictionary] objectForKey: @"CFBundleIdentifier"]);
		}
	}
	if ([plugins count] == 0)
	{
		MFLog(@"Failed to Load Any Plugins!");
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

- (NSMenu*)filesystemTypesMenuWithTarget:(id)target
{
	NSMenu* menu = [[[NSMenu alloc] initWithTitle:@"filesystems"] autorelease];
	NSEnumerator* pluginEnum = [plugins objectEnumerator];
	NSBundle* b;
	while(b = [pluginEnum nextObject])
	{
		NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle: [[b infoDictionary] objectForKey:@"FSLongType"] 
													   action:@selector(filesystemTypeChosen:) keyEquivalent:@""] autorelease];
		[item setRepresentedObject: [b principalClass]];
		[item setTarget: target];
		[menu addItem: item];
	}
	return menu;
}

#pragma mark Diskarbitration & Sleep Monitoring
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



// triggered when system waits
// we need to delay 5 sec before processing to wait for network to come online
- (void) handleWakeNotification:(NSNotification*)note
{
	[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(handleWakeTimer:) userInfo:nil repeats:NO];
}

// mounts all filesystems that were succesfully unmounted before sleep
- (void) handleWakeTimer:(NSTimer*)t
{
	NSEnumerator* e = [sleepMounts objectEnumerator];
	id <FuseFSProtocol> fs;
	while (fs = [e nextObject])
	{
		[self mountFilesystem: fs];
	}
	[sleepMounts release];
	sleepMounts = nil;
}

// unmounts all filesystems before system sleep
- (void) handleSleepNotification:(NSNotification*)note
{
	int result;
	[sleepMounts release];
	
	NSEnumerator* e = [mounts objectEnumerator];
	id <FuseFSProtocol> fs;
	sleepMounts = [[NSMutableArray alloc] init];
	while (fs = [e nextObject]) 
	{
		result = [self unmountFilesystem: fs];
		if (result == 0)
		{
			[sleepMounts addObject: fs];
		}
			
	}
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
- (NSMutableDictionary*) plugins
{
	return plugins;
}

- (NSMutableArray*)favorites
{
	return favorites;
}

#pragma mark URL Handling methods
- (void)registerURLHandling
{
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
												andSelector:@selector(handleURL:withReplyEvent:) 
										forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	MFLog(@"MacFusion Handling URL: %@", urlString);
	NSURL* myURL = [NSURL URLWithString:urlString];
	NSEnumerator* e = [plugins objectEnumerator];
	NSBundle* b;
	while(b = [e nextObject])
	{
		Class filesystemClass = [b principalClass];
		if ([filesystemClass canHandleURL: myURL])
		{
			id <FuseFSProtocol> fs = [[filesystemClass alloc] initWithURL: myURL];
			[self mountFilesystem:fs];
			[fs release];
		}
	}
}

#pragma mark Requirements Checking
// Check if an acceptable version of MacFuse is installed
- (void) checkForMacFuse
{
	NSArray* validVersions = [NSArray arrayWithObjects:@"0.3.0",@"0.4.0",nil];
	NSString* version = [self getMacFuseVersion];
	if (version == nil) // No MacFuse Found
	{
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES]; // take focus
		NSAlert* a = [NSAlert alertWithMessageText:@"MacFUSE is not Installed. Please install MacFUSE off Google's site to run MacFusion" 
						defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];		
		[a runModal];
		exit(0);
	}
	else
	{
		if ([validVersions containsObject: version])
		{
			// We're all good
			MFLog(@"MacFuse version %@ detected OK", version);
			return;
		}
		else if([[NSUserDefaults standardUserDefaults] objectForKey:@"VersionWarning"] == nil ) 
			// Untested MacFUSE version. Warn only once, then set a key so we won't warn again
		{
			
			NSString* m = [NSString stringWithFormat:@"Your version of MacFuse: %@ has not been validated with this version of MacFusion. This may cause problems in the operation of MacFusion.", version];
			[[NSAlert alertWithMessageText:m
							defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""] runModal];		
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"VersionWarning"];
		}
		else
		{
			MFLog(@"Untested MacFuse version %@ detected, not warning user", version);
		}
	}
	
}

- (NSString*)getMacFuseVersion
{
	NSString* extensionSearchRootPath = @"/Library/Extensions/";
	NSString* FuseFSBundleID = @"com.google.filesystems.fusefs";
	NSString* packageReceiptPath = @"/Library/Receipts/MacFUSE Core.pkg";
	NSString* version = nil;
	
	// Look for the package receipt 
	if ([[NSFileManager defaultManager] fileExistsAtPath:packageReceiptPath])
	{
		NSBundle* b = [NSBundle bundleWithPath: packageReceiptPath];
		if (b)
		{
			version = [[b infoDictionary] objectForKey:@"CFBundleShortVersionString"];
			if (version)
				return version;
		}
	}
	
	// Try to find the kext manually
	NSEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:extensionSearchRootPath];
	NSString* path = nil;
	
	while (path = [e nextObject])
	{
		NSString* bundlePath = [extensionSearchRootPath stringByAppendingString: path];
		NSBundle* b = [NSBundle bundleWithPath: bundlePath];
		if (b != nil)
		{
			NSString* bundleID = [b bundleIdentifier];
			if ([bundleID isEqualTo:FuseFSBundleID])
			{
				version = [[b infoDictionary] objectForKey:@"CFBundleVersion"];
				break;
			}
			
		}
	}
	return nil;
}

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
	[nonLoadedFavorites release];
	
	[plugins release];
	[statusMenuItem release];
	[super dealloc];
}

@end
