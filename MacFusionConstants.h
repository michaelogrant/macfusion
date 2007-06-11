//
//  MacFusionConstants.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/18/07.
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

// key names
extern NSString* favoritesKeyName;
extern NSString* favoritesFSTypeKeyName;
extern NSString* favoritesStoredObjectKeyName;
extern NSString* filesystemKeyName;
extern NSString* mountTimeoutKeyName;
extern NSString* mountFaliureReasonKeyName;
extern NSString* startOnLoginKeyName;
extern NSString* unmountOnSleepKeyName;

// notification names
extern NSString* FuseFSMountFailedNotification;
extern NSString* FuseFSMountedNotification;
extern NSString* FuseFSUnmountedNotification;
extern NSString* FuseFSLoggingNotification;

// growl notification names
extern NSString* growlFSMountFailedNotification;
extern NSString* growlFSMountSuccessNotification;
extern NSString* growlFSUnmountFailedNotification;

// status
extern NSString* FuseFSStatusUnmountedString;
extern NSString* FuseFSStatusWaitingToMountString;
extern NSString* FuseFSStatusMountedString;
extern NSString* FuseFSStatusMountFailedSring;


enum {
	FuseFSStatusUnmounted,
	FuseFSStatusWaitingToMount,
	FuseFSStatusMounted,
	FuseFSStatusMountFailed,
};

enum {
	NoChangeOnSleep,
	UnmountOnSleepRemountOnWake,
	UnmountOnSleepNoRemount,
};

enum {
	MacFusionLogTypeCore,
	MacFusionLogTypeConsoleOutput,
	MacFusionLogTypeError,
	MacFusionLogTypeNormal,
	MacFusionLogTypeMountUnmount,
};

// mount return enum
enum {
	FuseFSMountReturnOK,
	FuseFSMountReturnPathError,
};

// mount faliure reasons
extern NSString* FuseFSMountFaliureTimeout;
extern NSString* FuseFSMountFaliureTaskEnded;
extern NSString* FuseFSMountFaliurePathIssue;
extern NSString* FuseFSMountFaliureLibraryIssue;

extern NSString *ext;
extern NSString *appSupportSubpath;
extern NSString* selectTypeMenuItemName;