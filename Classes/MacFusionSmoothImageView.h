//
//  MacFusionSmoothImageView.h
//  MacFusion
//
//  Created by Michael Gorbach on 4/1/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MacFusionSmoothImageView : NSView 
{
	NSImage* image;
}

- (void)setImage:(NSImage*)image;
- (NSImage*)image;

@end
