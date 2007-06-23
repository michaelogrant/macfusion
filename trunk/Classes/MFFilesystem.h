//
//  MacFusionFileSystem.h
//  MacFusion
//
//  Created by Charles Parnot on 6/4/07.

#import "FuseFSProtocol.h"

/*
 
 MFFilesystem and MFNetworkFS are abstract classes that can be subclassed to create a new plugin.
 If you FS needs things like host, login, port and path, subclass MFNetworkFS.
 Otherwise, subclass MFFilesystem.
 
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

//additional initializer - for launching from URL
- (id)initWithURL:(NSURL*)url;

// The simplest way for these two is to override keysForSaving to return an
// array of all keys you want saved from your filesystem
// The default implementation of dictionaryForSaving will packing all non-nil
// keys into a dictionary.
// The default impleemntation of initWithDictionary will set all the object's
// values from dictionary keys/values

- (NSArray*)keysForSaving;
- (NSDictionary*)dictionaryForSaving;
- (id)initWithDictionary:(NSDictionary*)dic;

// you should override one of the 2 methods, or you get an exception
- (NSTask *)filesystemTask;
- (void)mount;

// text string to describe the FS (user-readable)
- (NSString *)fsDescription;

// will return an image generated from the file at iconPath
- (NSImage*)icon;
- (NSString*)defaultIconPath;

// exapnds the saving dictioary to add some things for the cell to do its work
- (NSDictionary*)dictionaryForDisplay;

// specify if your FS can handle the URL. No my default
+ (BOOL)canHandleURL:(NSURL*)url;

// by default, the mount path will be /Volumes/name, but you can override this
- (NSString*)mountPath;

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
