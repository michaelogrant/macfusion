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
#include "stdarg.h"

@interface MFLoggingController(PrivateAPI)
- (void)addToLogFile:(NSString*)entry;
@end

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
		[[NSNotificationCenter defaultCenter] addObserver: self 
												 selector:@selector(logMountFailed:) 
													 name:FuseFSMountFailedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(logMount:)
													 name:FuseFSMountedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector:@selector(logUnmount:)
													 name:FuseFSUnmountedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleAppTermination:)
													 name:NSApplicationWillTerminateNotification object:nil];
		
		log = [[NSMutableAttributedString alloc] init];
		NSString* logEntry = [NSString stringWithFormat:@" ---- MacFusion Started %@\n", [NSDate date]];
		[self addToLogFile: logEntry];
	}
	return self;
}

- (void) windowDidLoad
{
	[[self window] setLevel:NSFloatingWindowLevel];
	[[self window] center];
	[[logTextView textStorage] setAttributedString:log];
}

#pragma mark Logging Functions
- (void)addToLogWindow:(NSString*)entry withColor:(NSColor*)color
{
	NSDictionary* textAttributes = [NSDictionary dictionaryWithObjectsAndKeys: color, 
		NSForegroundColorAttributeName, [NSFont systemFontOfSize: 12], NSFontAttributeName, nil];

	NSAttributedString* new = [[NSAttributedString alloc] initWithString: entry
															  attributes: textAttributes];
	[new autorelease];
	[log appendAttributedString:new];
	NSRange userSelection = [logTextView selectedRange];
	
	// FIXME: this is a bad hack, but bindings dont seem to work
	[[logTextView textStorage] setAttributedString:log];
    
    if (userSelection.length > 0)
        [logTextView setSelectedRange:userSelection];
    else
        [logTextView scrollRangeToVisible:NSMakeRange([log length] - 1,0)];
}

- (void)addToLogFile:(NSString*)entry
{
	NSFileHandle *writeHandle;
	NSString* logFile = [NSString stringWithFormat:@"%@/Library/Logs/MacFusion.log", NSHomeDirectory()];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:logFile])
		[[NSFileManager defaultManager] createFileAtPath:logFile contents:nil attributes:nil];
	
	writeHandle = [NSFileHandle fileHandleForWritingAtPath:logFile]; 
	[writeHandle truncateFileAtOffset:[writeHandle seekToEndOfFile]]; 
	
	[writeHandle writeData:[entry dataUsingEncoding:nil]]; //actually write the data
}

- (void) logMountFailed:(NSNotification*)note
{
	[self logMessage:@"Mount Failed" ofType:MacFusionLogTypeError sender:[note object]];
}

- (void) logMount:(NSNotification*)note
{
	[self logMessage:@"Mount OK" ofType:MacFusionLogTypeMountUnmount sender:[note object]];
}

- (void) logUnmount:(NSNotification*)note
{
	[self logMessage:@"Unmount OK" ofType:MacFusionLogTypeMountUnmount sender:[note object]];
}

- (void) logMessage:(NSString*)message 
			 ofType:(int)type 
			 sender:(id)sender
{
	NSColor* color;
	
	// Is there a better way to do this mapping? A Dictionary doesn't seem nice as the keys are integers.
	switch(type)
	{
		case MacFusionLogTypeMountUnmount:
			color = [NSColor blueColor];
			break;
		case MacFusionLogTypeError:
			color = [NSColor redColor];
			break;
		case MacFusionLogTypeNormal:
			color = [NSColor blackColor];
			break;
		case MacFusionLogTypeConsoleOutput:
			color = [NSColor grayColor];
			break;
		case MacFusionLogTypeCore:
			color = [NSColor purpleColor];
			break;
	}
	
//	NSArray* splitMessage = [message componentsSeparatedByString:@"\n"];
//	NSString* joinMessage = [splitMessage componentsJoinedByString:@" "];
	NSString* sourceName;
	
	if ([sender conformsToProtocol:@protocol(FuseFSProtocol)])
		sourceName = [sender name];
	else
		sourceName = @"MacFusion Core";
	
	NSString* newEntry;
	if ([message characterAtIndex: [message length]-1] == '\n')
		newEntry = [NSString stringWithFormat:@"%@: %@", sourceName, message];
	else
		newEntry = [NSString stringWithFormat:@"%@: %@\n", sourceName, message];
	
	
	[self addToLogWindow:newEntry withColor:color];
	[self addToLogFile:newEntry];
}

- (void) handleAppTermination:(NSNotification*)note
{
	NSString* logEntry = [NSString stringWithFormat:@" ---- MacFusion Terminated %@\n", [NSDate date]];
	[self addToLogFile: logEntry];
}

- (void) dealloc 
{
	[log release];
	[super dealloc];
}

void MFLog(NSString* format, ...)
{
	MFLoggingController* logger = [MFLoggingController sharedLoggingController];
	id core = [[NSApplication sharedApplication] delegate];
	
	// get a reference to the arguments on the stack that follow
    // the format paramter
    va_list argList;
    va_start (argList, format);
	
    // NSString luckily provides us with this handy method which
    // will do all the work for us, including %@
    NSString *string;
    string = [[NSString alloc] initWithFormat: format
									arguments: argList];
    va_end  (argList);
	[logger logMessage:string ofType:MacFusionLogTypeCore sender:core]; 
	
    [string release];
}


@end
