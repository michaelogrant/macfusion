//
//  FuseFSProtocol.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//
// This is the primary protocol that all MacFusion filesystem plugins
// must implement.



@protocol FuseFSProtocol <NSObject>

// accessors for variables common to all filesystems

- (NSString *)name; // the volume name of the mounted FS
- (int)status; // status of the fileSystem (#defined)
- (NSString*)longStatus; // readable status
- (BOOL)pingDiskarb; // whether to ping disk arbitration`
- (NSString*)mountPath; // path at which the FS is mountved
- (BOOL)mountOnStartup;

// setters
- (void)setName:(NSString*)s;
- (void)setStatus:(int)s;
- (void)setPingDiskarb:(BOOL)yn;
- (void)setMountOnStartup:(BOOL)yn;

// the actual important methods 
- (void)mount;

// method to return error when a fileSystem isn't mounting
// you should fill this with parsed output from your task
- (NSString*)errorString;

// methods to load to/from defaults
// should return/take an objects that can be stored in plist format
- (id)storageObjectForDefaults;
- (id)initWithStoredObject:(id)stored;

// description methods
- (NSString *)fsType; // the filesystem type (SSHFS, etc)
- (NSString *)fsLongType; // human-readable version of the filesystem type
- (NSString *)fsDescription; // a string describing this FS

@end