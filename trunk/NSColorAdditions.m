//
//  NSColorAdditions.m
//  MacFusion
//
//  Created by Eric Astor on 5/13/07.
//  Copyright 2007 Eric Astor. All rights reserved.
//

#import "NSColorAdditions.h"


@implementation NSColor(NSColorTransforms)

- (NSColor*) hsbTransformWithHueFactor: (float)hueFactor        hueOffset: (float)hueOffset
							 satFactor: (float)satFactor        satOffset: (float)satOffset
						  brightFactor: (float)brightFactor  brightOffset: (float)brightOffset
{
	float hue, sat, bright, alpha;
	[self getHue: &hue saturation: &sat brightness: &bright alpha: &alpha];
	hue    =    hueFactor * hue    + hueOffset;
	sat    =    satFactor * sat    + satOffset;
	bright = brightFactor * bright + brightOffset;
	return [NSColor colorWithDeviceHue: hue saturation: sat brightness: bright alpha: alpha];
}

@end
