//
//  MacFusionFSCell.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/12/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionFSCell.h"


@implementation MacFusionFSCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{

	BOOL doHighlight = ([self isHighlighted] &&
	 [[controlView window] firstResponder] == controlView &&
	 [[controlView window] isKeyWindow]);
	
	NSString* description = [[self objectValue] objectForKey: @"fsDescription"];
	NSString* name = [NSString stringWithFormat: @"%@ (%@)", [[self objectValue] objectForKey: @"name"],
		[[self objectValue] objectForKey: @"fsLongType"]];
	
	NSMutableDictionary* nameAttributes = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* descriptionAttributes = [[NSMutableDictionary alloc] init];
	NSMutableParagraphStyle* pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[pStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	[nameAttributes setObject: pStyle forKey:NSParagraphStyleAttributeName];
	[descriptionAttributes setObject: pStyle forKey:NSParagraphStyleAttributeName];
	[nameAttributes setObject: [NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName];
	[descriptionAttributes setObject: [NSFont systemFontOfSize:12] forKey:NSFontAttributeName];
			
	if (doHighlight)
	{
		[nameAttributes setObject: [NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];
		[descriptionAttributes setObject: [NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];
	}
	else
	{
		[nameAttributes setObject: [NSColor controlTextColor] forKey:NSForegroundColorAttributeName];
		[descriptionAttributes setObject: [NSColor grayColor] forKey:NSForegroundColorAttributeName];
	}
	
	int nameHeight = [name sizeWithAttributes: nameAttributes].height;
	int descriptionHeight = [description sizeWithAttributes: descriptionAttributes].height;
	
	if (nameHeight < cellFrame.size.height)
	{
		cellFrame.origin.y += (cellFrame.size.height - (nameHeight + descriptionHeight)) / 2.0;
	}
	
	[name drawInRect:cellFrame withAttributes: nameAttributes];
	cellFrame.origin.y += nameHeight;
	[description drawInRect: cellFrame withAttributes: descriptionAttributes];
	
	[nameAttributes release];
	[descriptionAttributes release];
}

@end
