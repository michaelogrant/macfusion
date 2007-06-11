//
//  MacFusionTableView.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/17/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionTableView.h"


@implementation MacFusionTableView

- (void)rightMouseDown:(NSEvent*)theEvent
{
	
	[self columnAtPoint: [theEvent locationInWindow]];
	int r = [self rowAtPoint: [self convertPoint: [theEvent locationInWindow] toView: nil]];
	if (r != -1) {
		[self selectRow: r byExtendingSelection:NO];
		
		NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
											location:[theEvent locationInWindow]
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
}

@end
