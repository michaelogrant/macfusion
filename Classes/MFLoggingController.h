//
//  MFLoggingController.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Cocoa/Cocoa.h>
#import "MFMainController.h"
#import "FuseFSProtocol.h"
#import "MacFusionConstants.h"

@interface MFLoggingController : NSWindowController {
	IBOutlet NSTextView* logTextView;
	NSMutableAttributedString* log;
}

+ (MFLoggingController*)sharedLoggingController;
- (void) logMessage:(NSString*)message 
			 ofType:(int)type 
			 sender:(id)sender;

@end

// Logging function for MacFusion's core, to replace NSLog
void MFLog(NSString* s, ...);
