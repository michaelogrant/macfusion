//
//  MacFusionFileSystem.h
//  MacFusion
//
//  Created by Charles Parnot on 6/4/07.

#import "FuseFSProtocol.h"

/*
 As an alternative to implementing the FuseFSProtocol in your own class, you could instead subclass MacFusionFileSystem, which provides already the following functionality:
 
 - keeps track of name, mountOnStartup (default NO), status
 - also keeps track of hostName, login, path, which is useful for filesystem using a server (e.g. FTPFS, SSHFS, XgridFS,...)
 - manages the process that corresponds to the client filesystem

 All you have to do is:
 - subclass MacFusionFileSystem
 - add an image file 'XXXX.YYY' as icon, where XXXX is the same name as the class (or override the 'icon' method)
 - override 'fileSystemTask' to return an autoreleased task object where you should define everything (do not worry about the output pipe and about extra environment variable that may be needed and will be added by the superclass)
 - override dictionaryForSaving and initWithDictionary: if you have additional ivars/settings you want to be persistent
 - override any other of the mehtods listed below as you see fit
 
 TODO: add more instructions on how to link to the executable using bundle_loader build setting
 
 */

@interface MFFilesystem : NSObject  <FuseFSProtocol>
{
	//basic info about the FS
	NSString* name;
	BOOL mountOnStartup;
	int status;
	NSString* iconPath;
	NSString* advancedOptions;

	//ivars used to start separate processes - lots of boilerplate code provided by superclass (see methods below)
	NSTask* task;
	NSPipe* outputPipe;
	NSPipe* inputPipe;
	NSString* recentOutput;
}

//PLEASE OVERRIDE
//the methods below will usually need to be overriden

//designated initializer - be sure to first call [super initWithURL:url] in your code
- (id)initWithURL:(NSURL*)url;

//you may first call super, which takes care of the following ivars: name, mountOnStartup, hostName, login, path
//if no additional settings, you don't need to override this
//otherwise, add your own values to this list and return the resulting dictionary
- (NSArray*)keysForSaving;

//you should first call super, which takes care of the following ivars: name, mountOnStartup, hostName, login, path
//then setup the other values you are interested in (if none, don't need to override)
- (id)initWithDictionary:(NSDictionary*)dic;

//you should override one of the 2 methods, or you get an exception
- (NSTask *)filesystemTask;
- (void)mount;


//MAYBE OVERRIDE
//the methods below provide default implementations that will usually be enough, but overriding them might be useful in some cases

//usually what you want: login@host:path
- (NSString *)fsDescription;

//the default icon will be looked for in the bundles, based on subclass name, e.g. looking for "SSHFS.xxx" when subclass name = SSHFS
- (NSImage*)icon;

//the default implementation will return a dictionary with fsDescription, fsLongType and status
- (NSDictionary*)dictionaryForDisplay;

//by default returns NO
+ (BOOL)canHandleURL:(NSURL*)url;

//by default, the mount path will be /Volumes/name, but you can override this
- (NSString*)mountPath;



//DO NOT OVERRIDE
//you generally should not override any of the methods below

//the superclass implementation simply calls 'initWithURL' with empty string
- (id)init;

//to comply with NSCopy protocol
- (id)copyWithZone:(NSZone *)zone;

//the values for these are pooled from the Info.plist of the plugin bundle, which are also the values used by MacFusion to tell one plugin from the other - you have no good reason to override these!
- (NSString *)fsType;
- (NSString *)fsLongType;

//the libfuse library may get installed at various paths; this method should smart enought to know where it is
- (NSString*)getPathForLibFuse;

- (void)removeMountPoint;
- (BOOL)setupMountPoint;

//getters
- (NSString *)name;
- (int)status;
- (NSString*)longStatus;
- (BOOL)mountOnStartup; //default is NO
- (NSString*)recentOutput;
- (NSString*)iconPath;
- (NSString*)advancedOptions;

// setters
- (void)setName:(NSString*)s;
- (void)setStatus:(int)s;
- (void)setMountOnStartup:(BOOL)yn; //default is NO
- (void)setIconPath:(NSString*)aString;
- (void)setAdvancedOptions:(NSString*)aString;

@end
