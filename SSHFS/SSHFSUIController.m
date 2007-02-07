//
//  SSHFSUIController.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/15/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "SSHFSUIController.h"
#import "SSHFS.h"

NSString* SSHFSNameError = @"You must specify a valid name for the Filesystem";
NSString* SSHFSHostError = @"You must specify a valid SSH Host Name";
NSString* SSHFSLoginError = @"You must specify a valid Login Name";
NSString* SSHFSPortError = @"Port can not be 0";


@implementation SSHFSUIController
- (id) init 
{
	NSLog(@"SSHFSUI init");
	self = [super init];
	if (self != nil) 
	{
		// setup my filesystem object
		fileSystem = [[SSHFS alloc] init];
		
		// get our view from the nib & load it
		[NSBundle loadNibNamed:@"SSHFS.nib" owner:self];
	}
	
	return self;
}

- (id) initWithFS:(id <FuseFSProtocol>) fs
{
	self = [super init];
	fileSystem = [fs retain];
	[NSBundle loadNibNamed:@"SSHFS.nib" owner:self];
	return self;
}

- (BOOL) validateFilesystem:(NSString**)error
{
	if ([fileSystem name] == nil || [fileSystem name] == @"")
	{
		*error = SSHFSNameError;
		return NO;
	}
	if ([fileSystem hostName] == nil || [fileSystem hostName] == @"")
	{
		*error = SSHFSHostError;
		return NO;
	}
	if ([fileSystem login] == nil || [fileSystem login] == @"")
	{
		*error = SSHFSLoginError;
	}
	if ([fileSystem port] == 0 || [fileSystem port] > 1000)
	{
		*error = SSHFSPortError;
		return NO;
	}
	else
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

- (void) commitEdits
{
	[fsController commitEditing];
}

- (void) dealloc 
{
	[fileSystem release];
	[super dealloc];
}

@end
