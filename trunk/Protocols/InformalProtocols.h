//
//  InformalProtocols.h
//  MacFusion
//
//  Created by Michael Gorbach on 3/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FuseFSProtocol.h"

@interface NSObject(MacFusionEditControllerDelegate)

- (void) editCompleteForFilesystem:(id <FuseFSProtocol>)fs WithSuccess:(BOOL)success;


@end
