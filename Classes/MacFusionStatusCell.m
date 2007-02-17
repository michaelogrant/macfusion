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
	
	NSBezierPath* p = [NSBezierPath bezierPathWithRoundedRect: roundedRect cornerRadius: 10.0]; 
	NSShadow* s = [[NSShadow alloc] init];;
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

- (CTGradient*)gradientForStatus:(NSString*)status
{
	// First Color Always White, Other 2 determined by status
	NSColor* color1 = [NSColor whiteColor];
	NSColor* color2;
	NSColor* color3;
	
	if ([status isEqualTo: @"Mounted"])
	{
		color2 = [NSColor colorWithDeviceRed: 144/255. green:172/255. blue:40/255. alpha:1];
		color3 = [NSColor colorWithDeviceRed:236/255. green:255/255. blue:133/255. alpha:1];
	}
	else if ([status isEqualTo: @"Unmounted"])
	{
		color2 = [NSColor colorWithDeviceRed: 0 green:133/255. blue:239/255. alpha:1];
		color3 = [NSColor colorWithDeviceRed:177/255. green:212/255. blue:244/255. alpha:1];
	}
	else if ([status isEqualTo: @"Mount Failed"])
	{
		color2 = [NSColor colorWithDeviceRed: 1 green:70/255. blue:54/255. alpha:1];
		color3 = [NSColor colorWithDeviceRed: 1 green:172/255. blue:161/155. alpha:1];
	}
	else
	{
		color2 = [NSColor colorWithDeviceRed: 232/255. green:168/255. blue:40/255. alpha:1];
		color3 = [NSColor colorWithDeviceRed: 254/255. green:254/255. blue:141/255. alpha:1];
	}
	
	CTGradient* grad = [CTGradient gradientWithBeginningColor: color1 endingColor:color3];
	grad = [grad addColorStop: color2 atPosition:0.5];
	
	return grad;
}
@end
