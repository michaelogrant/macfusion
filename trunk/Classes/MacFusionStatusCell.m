//
//  MacFusionStatusCell.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/12/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionStatusCell.h"
#import "CTGradient.h"
#import "RoundedRectangles.h"
#import "NSColorAdditions.h"

@interface MacFusionStatusCell (PrivateAPI)
- (CTGradient*)gradientForStatus:(NSString*)status;
@end

@implementation MacFusionStatusCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	[NSGraphicsContext saveGraphicsState];
	NSString* status = [self objectValue];
	CTGradient* gradient = [self gradientForStatus: status];
	
	float imagePadding = 5;
	NSRect roundedRect = cellFrame;
	
	roundedRect.size.width *= .8;
	roundedRect.size.height *= .6;
	roundedRect.origin.x = cellFrame.origin.x + cellFrame.size.width - roundedRect.size.width - imagePadding;
	roundedRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - roundedRect.size.height)/2;
	
	NSBezierPath* p = [NSBezierPath bezierPathWithRoundedRect: roundedRect 
												 cornerRadius: 10.0]; 
	NSShadow* s = [[NSShadow alloc] init];
	[s setShadowColor: [NSColor blackColor]];
	[s setShadowOffset: NSMakeSize(-1,-1)];
	[s setShadowBlurRadius: 4];
	[s set];
	
	[[NSColor grayColor] set];
	[p stroke];
	[p addClip];
	[gradient fillRect: roundedRect angle:90];
	[NSGraphicsContext restoreGraphicsState];
	
	NSRect textRect = roundedRect;
	NSDictionary* textAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor blackColor], 
		NSForegroundColorAttributeName, [NSFont systemFontOfSize: 12], NSFontAttributeName, nil];
	NSSize textSize = [status sizeWithAttributes: textAttributes];
	
	textRect.origin.y += (textRect.size.height - textSize.height)/2;
	textRect.origin.x += (textRect.size.width - textSize.width)/2;
	
	[status drawInRect: textRect withAttributes: textAttributes];
}

- (CTGradient*)gradientForStatus: (NSString*)status
{
	NSDictionary* colorDic = [NSDictionary dictionaryWithObjectsAndKeys:
		[[NSColor windowFrameColor] colorUsingColorSpaceName: NSDeviceRGBColorSpace], @"Unmounted",
		[NSColor colorWithDeviceHue:  73/360. saturation: 0.77 brightness: 0.67 alpha: 1], @"Mounted",
		[NSColor colorWithDeviceHue:   5/360. saturation: 0.79 brightness: 1.00 alpha: 1], @"Mount Failed",
		nil];
	//Old "Unmounted" blue: [NSColor colorWithDeviceHue: 207/360. saturation: 1.00 brightness: 0.94 alpha: 1]

	
	NSColor* statusColor = [colorDic objectForKey: status];
	if (!statusColor)
	{
		statusColor = [NSColor colorWithDeviceRed: 232/255. green:168/255. blue:40/255. alpha:1];
	}
	
	// Dynamically generate gradient - parameters determined by trial-and-error
	NSColor* startColor = [statusColor hsbTransformWithHueFactor: 1.      hueOffset: 0.
													   satFactor: 1/4.    satOffset: 0.
													brightFactor: 1/4. brightOffset: 3/4.];
	NSColor*   endColor = [statusColor hsbTransformWithHueFactor: 1.	  hueOffset: 0.
													   satFactor: 5/12.   satOffset: 0.
													brightFactor: 2/3. brightOffset: 1/3.];
	
	CTGradient* grad = [CTGradient gradientWithBeginningColor: startColor endingColor: endColor];
	grad = [grad addColorStop: statusColor atPosition:0.5];
	
	return grad;
}
@end
