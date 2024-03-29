//
//  MacFusionActionButton.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionActionButton.h"


@implementation MacFusionActionButton
- (void)mouseDown:(NSEvent*)theEvent
{
	[self highlight: YES];

	NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
	point.y -= NSHeight([self frame]) + 4;
	point.x -= 1;
	
	NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
										location:point
								   modifierFlags:[theEvent modifierFlags]
									   timestamp:[theEvent timestamp]
									windowNumber:[[theEvent window] windowNumber]
										 context:[theEvent context]
									 eventNumber:[theEvent eventNumber]
									  clickCount:[theEvent clickCount]
										pressure:[theEvent pressure]];
	[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
	[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
}

- (void)mouseUp:(NSEvent*)event
{
	[self highlight: NO];
}

@end
