//
//  PreferencesController.h
//  MacFusion
//
//  Created by Michael Gorbach on 2/24/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFMainController.h"
@class MFMainController;


@interface MFPrefsController : NSWindowController {

}

- (IBAction) loginItemChanged:(id) sender;
- (IBAction) sleepUnmountChanged:(id) sender;

@end
