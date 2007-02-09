//
//  FuseUIProtocol.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/15/07.
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

// This is the protocol for the GUI objects associarted with filesystems

#import "../Protocols/FuseFSProtocol.h"
@protocol FuseUIProtocol <NSObject>

- (NSView*)configurationView; // method to get the created by this plugin for configured the filesystem
- (id <FuseFSProtocol>) fileSystem; // the filesystem object itself
- (BOOL) validateFilesystem:(NSString**)error; // method to confirm that the object is mostly valid and ready to store/try to mount, error passed by ref.
- (void) commitEdits;

- (id) initWithFS:(id <FuseFSProtocol>)fs;
@end
