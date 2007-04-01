//
//  MacFusionSmoothImageView.m
//  MacFusion
//
//  Created by Michael Gorbach on 4/1/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionSmoothImageView.h"


@implementation MacFusionSmoothImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}

- (NSImage*)image
{
	return image;
}

- (void)setImage:(NSImage*)newImage
{
	[newImage retain];
	[image release];
	image = newImage;
}
@end
