//
//  FuseFSProtocol.h
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


// This is the primary protocol that all MacFusion filesystem plugins
// must implement.

@protocol FuseFSProtocol < NSObject, NSCopying >

// accessors for variables common to all filesystems

- (NSString *)name;
- (int)status;
- (NSString*)longStatus;			// readable status
- (NSString*)mountPath;
- (BOOL)mountOnStartup;				// mount on program startup
- (NSImage*)icon;					// icon to represent FS type

// setters
- (void)setName:(NSString*)s;
- (void)setStatus:(int)s;
- (void)setMountOnStartup:(BOOL)yn;

// the actual important methods 
- (void)mount;

// method to return error when a fileSystem isn't mounting
// you should fill this with parsed output from your task
- (NSString*)recentOutput;

- (NSDictionary*)dictionaryForDisplay;				// Dictionary with display info
- (NSDictionary*)dictionaryForSaving;				// should return dictionary to go to defaults
- (id)initWithDictionary:(NSDictionary*)dic;		// initialize object using defaults dictionary

// description methods
- (NSString *)fsType; // the filesystem type (SSHFS, etc)
- (NSString *)fsLongType; // human-readable version of the filesystem type
- (NSString *)fsDescription; // a string describing this FS

// URL Handling ... so the MacFusion app can handle FTP and SFTP urls
+ (BOOL)canHandleURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)url;
- (NSString*)getPathForLibFuse;

@end