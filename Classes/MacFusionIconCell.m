//
//  MacFusionIconCell.m
//  MacFusion
//
//  Created by Michael Gorbach on 3/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MacFusionIconCell.h"


@implementation MacFusionIconCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSImage* myImage = [self objectValue];
	NSImageRep *sourceImageRep = [myImage bestRepresentationForDevice:nil];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[myImage setFlipped:YES];
	[myImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}
@end
