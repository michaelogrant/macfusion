//
//  MFNotificationWatcher.m
//  MacFusion
//
//  Created by Michael Gorbach on 7/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MFNotificationWatcher.h"


@implementation MFNotificationWatcher
+ (MFNotificationWatcher*) sharedNotificationWatcher
{
	static MFNotificationWatcher* notificationWatcher = nil;
	
	if (!notificationWatcher)
	{
		notificationWatcher = [[self alloc] init];
	}
	
	return notificationWatcher;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		[self monitorNotifications];
	}
	return self;
}

- (void)monitorNotifications
{
	NSString* observedObject = @"com.google.filesystems.fusefs.unotifications";
	NSDistributedNotificationCenter* center = [NSDistributedNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(notificationReceived:) name:nil object:observedObject];
}

- (void)notificationReceived:(NSNotification*)note
{
	MFLog(@"Notification received %@", [note name]);
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
