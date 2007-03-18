//
//  PreferencesController.h
//  MacFusion
//
//  Created by Michael Gorbach on 2/24/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacFusionController.h"
@class MacFusionController;


@interface PreferencesController : NSWindowController {

}

- (IBAction) loginItemChanged:(id) sender;
- (IBAction) sleepUnmountChanged:(id) sender;

@end
