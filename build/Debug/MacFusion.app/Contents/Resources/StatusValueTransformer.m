//
//  StatusValueTransformer.m
//  MacFusion
//
//  Created by Michael Gorbach on 2/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "StatusValueTransformer.h"


@implementation StatusValueTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformations
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSLog([value class]);
	return @"TEST";
}

@end
