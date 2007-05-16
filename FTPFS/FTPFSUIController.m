//
//  FTPFSUIController.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/15/07.
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

#import "FTPFSUIController.h"
#import "FTPFS.h"

NSString* FTPFSNameError = @"You must specify a valid name for the Filesystem";
NSString* FTPFSHostError = @"You must specify a valid FTP Host Name";
NSString* FTPFSLoginError = @"You must specify a valid Login Name";
NSString* FTPFSPortError = @"Port out of Range (Must be 1 to 65535)";


@implementation FTPFSUIController
- (id) init 
{
	self = [super init];
	if (self != nil) 
	{
		// setup my filesystem object
		fileSystem = [[FTPFS alloc] init];
		
		// get our view from the nib & load it
		[NSBundle loadNibNamed:@"FTPFS.nib" owner:self];
	}
	
	return self;
}

- (id) initWithFS:(id <FuseFSProtocol>) fs
{
	self = [super init];
	fileSystem = [fs retain];
	[NSBundle loadNibNamed:@"FTPFS.nib" owner:self];
	return self;
}

- (BOOL) validateFilesystem:(NSString**)error
{
	if ([fileSystem name] == nil || [fileSystem name] == @"")
	{
		*error = FTPFSNameError;
		return NO;
	}
	if ([fileSystem hostName] == nil || [fileSystem hostName] == @"")
	{
		*error = FTPFSHostError;
		return NO;
	}
	
	return YES;
}

- (id <FuseFSProtocol>) fileSystem
{
	return fileSystem;
}

- (NSView*) configurationView
{
	return configurationView;
}

- (void) dealloc 
{
	[fileSystem release];
	[super dealloc];
}

@end
