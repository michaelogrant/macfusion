//
//  MFLoggingController.h
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

#import "MFLoggingController.h"


@implementation MFLoggingController
static MFLoggingController* sharedLoggingController = nil;

+ (MFLoggingController*) sharedLoggingController
{
	if (sharedLoggingController == nil)
		[[self alloc] init];
	
	return sharedLoggingController;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedLoggingController == nil)
	{
		sharedLoggingController = [super allocWithZone:zone];
		return sharedLoggingController;
	}
	
	return nil;
}

- (id) init {
	self = [super initWithWindowNibName:@"MacFusionLogging"];
	if (self != nil) {
		log = [[NSMutableAttributedString alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver: self 
												 selector:@selector(logMountFailiure:) 
													 name:FuseFSMountFailedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(logMountSuccess:)
													 name:FuseFSMountedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(logUnmountSuccess:)
													 name:FuseFSUnmountedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(logMessage:)
													 name:FuseFSUnmountedNotification object:nil];
	}
	return self;
}

- (void) windowDidLoad
{
	[[self window] center];
}

#pragma mark Logging Functions
- (void)addToLog:(NSString*)entry withColor:(NSColor*)color
{
	NSAttributedString* new = [[NSAttributedString alloc] initWithString: entry];
	[new autorelease];
	[self willChangeValueForKey:@"log"];
	[log appendAttributedString: new];
	[self didChangeValueForKey:@"log"];
	NSLog(entry);
}

- (NSMutableAttributedString*)log
{
	return log;
}

- (void) logMountFaliure:(NSNotification*)note
{
	NSString* newEntry = [NSString stringWithFormat:@"%@: Mount Failed\n", [[note object] name]];
	[self addToLog: newEntry withColor:[NSColor redColor]];
}

- (void) logMountSuccess:(NSNotification*)note
{
	NSString* newEntry = [NSString stringWithFormat:@"%@: Mount Succesful\n", [[note object] name]];
	[self addToLog: newEntry withColor:[NSColor blueColor]];
}

- (void) logUnmountSuccess:(NSNotification*)note
{
	NSString* newEntry = [NSString stringWithFormat:@"%@: Unmount Succesful\n", [[note object] name]];
	[self addToLog: newEntry withColor:[NSColor blueColor]];
}

- (void) logMessage:(NSNotification*)note
{
	id <FuseFSProtocol> fs = [note object];
	NSString* message = [[note userInfo] objectForKey:@"Message"];
	NSString* type = [[note userInfo] objectForKey:@"MessageType"];
	
	NSString* newEntry = [NSString stringWithFormat:@"%@: %@\n", [fs name], message];
	if ([type isEqualToString:@"Output"])
		[self addToLog: newEntry withColor:[NSColor greenColor]];
	if ([type isEqualToString:@"Normal"])
		[self addToLog: newEntry withColor:[NSColor blackColor]];
	if ([type isEqualToString:@"Error"])
		[self addToLog: newEntry withColor:[NSColor redColor]];
}

- (void) dealloc {
	[log release];
	[super dealloc];
}


@end
