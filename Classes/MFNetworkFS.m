//
//  MacFusionNetworkFS.m
//  MacFusion
//
//  Created by Michael Gorbach on 6/9/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFNetworkFS.h"


@implementation MFNetworkFS
- (id) init {
	self = [super init];
	if (self != nil) {
		[self setHostName:@""];
		[self setPath:@""];
		[self setLogin:NSUserName()];
	}
	return self;
}

- (id) initWithURL:(NSURL*)url
{
	self = [self init];
	if (self !=  nil)
	{
		[self setHostName:[url host]];
		[self setPath:[url path]];
		[self setLogin:[url user]];
	}
	return self;
}

- (NSArray*)keysForSaving
{
	NSMutableArray* storedKeys = [NSMutableArray arrayWithArray:[super keysForSaving]];
	NSArray* keyNames = [NSArray arrayWithObjects:@"hostName", @"login", @"path", @"port", nil];
	[storedKeys addObjectsFromArray:keyNames];
	return [[storedKeys copy] autorelease];
}

- (NSString*)fsDescription
{
	NSMutableString* description = [NSMutableString stringWithString:@""];
	if ([self login] != nil && [[self login] length] > 0)
		[description appendFormat:@"%@@", [self login]];
	[description appendString:[self hostName]];
	if ([self path] != nil && [[self path] length] > 0)
		[description appendFormat:@":%@", [self path]];
	return [[description copy] autorelease];
}

#pragma mark Accessors
- (NSString*)hostName
{
	return hostName;
}

- (NSString*)login
{
	return login;
}

- (NSString*)path
{
	return path;
}

- (int)port
{
	return port;
}

#pragma mark Setters
- (void)setHostName:(NSString*)s
{
	[s retain];
	[hostName release];
	hostName = s;
}

- (void)setLogin:(NSString*)s
{
	[s retain];
	[login release];
	login = s;
}

- (void)setPath:(NSString*)s
{
	[s retain];
	[path release];
	path = s;
}

- (void)setPort:(int)p
{
	port = p;
}

- (void) dealloc {
	[hostName release];
	[path release];
	[login release];
	[super dealloc];
}

@end
