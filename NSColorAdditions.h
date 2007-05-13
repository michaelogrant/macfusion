//
//  NSColorAdditions.h
//  MacFusion
//
//  Created by Eric Astor on 5/13/07.
//  Copyright 2007 Eric Astor. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor(NSColorTransforms)

// Returns a new color, the result of an affine transform (factor * x + offset) in HSB coordinates
- (NSColor*) hsbTransformWithHueFactor: (float)hueFactor        hueOffset: (float)hueOffset
							 satFactor: (float)satFactor        satOffset: (float)satOffset
						  brightFactor: (float)brightFactor  brightOffset: (float)brightOffset;

@end
