//
//  MacFusionNetworkFS.m
//  MacFusion
//
//  Created by Michael Gorbach on 6/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MFNetworkFS.h"


@implementation MFNetworkFS
- (id)initWithDictionary:(NSDictionary*)dic
{
	self = [super initWithDictionary:dic];
	[self setHostName: [dic objectForKey: @"hostName"]];
	[self setLogin: [dic objectForKey: @"login"]];
	[self setPath: [dic objectForKey:@"path"]];
	return self;
}

- (NSDictionary*)dictionaryForSaving
{
	NSMutableDictionary *base = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryForSaving]];
	NSArray* keyNames = [NSArray arrayWithObjects:@"hostName", @"login", @"path", nil];
	NSDictionary *extra = [self dictionaryWithValuesForKeys:keyNames];
	[base addEntriesFromDictionary:extra];
	return [[base copy] autorelease];
}

- (NSString*)fsDescription
{
	if ([[self login] isEqualTo: NSUserName()])
		return [NSString stringWithFormat:@"%@%@",
			[self hostName], [self path]];
	else
		return [NSString stringWithFormat:@"%@@%@%@",
			[self login], [self hostName], [self path]];
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
	if (s==nil) s=@"";
	[s retain];
	[path release];
	path = s;
}

- (void) dealloc {
	[hostName release];
	[path release];
	[login release];
	[super dealloc];
}

@end
