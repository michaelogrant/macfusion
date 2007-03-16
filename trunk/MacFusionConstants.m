//
//  MacFusionConstants.m
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

#import "MacFusionConstants.h"

NSString* favoritesKeyName = @"Favorites";
NSString* favoritesFSTypeKeyName = @"FSType";
NSString* favoritesStoredObjectKeyName = @"StoredObject";
NSString* filesystemKeyName = @"Filesystem";
NSString* mountTimeoutKeyName = @"mountTimeout";
NSString* mountFaliureReasonKeyName = @"mountFaliureReason";
NSString* startOnLoginKeyName = @"startOnLogin";
NSString* unmountOnSleepKeyName = @"unmountOnSleep";

NSString* FuseFSMountFailedNotification = @"FuseFSMountFailed";
NSString* FuseFSMountedNotification = @"FuseFSMounted";
NSString* FuseFSUnmountedNotification = @"FuseFSUnmounted";

NSString* growlFSMountFailedNotification = @"Mount Faliure";
NSString* growlFSMountSuccessNotification = @"Mount Success";
NSString* growlFSUnmountFailedNotification = @"Unmount Faliure";

NSString* FuseFSMountFaliureTimeout = @"Timeout";
NSString* FuseFSMountFaliureTaskEnded = @"Task Ended";
NSString* FuseFSMountFaliurePathIssue = @"Mountpoint Setup Failed";

NSString* FuseFSStatusUnmountedString = @"Unmounted";
NSString* FuseFSStatusWaitingToMountString = @"Waiting to Mount";
NSString* FuseFSStatusMountedString = @"Mounted";
NSString* FuseFSStatusMountFailedString = @"Mount Failed";

NSString *ext = @"plugin";
NSString *appSupportSubpath = @"Application Support/MacFusion/PlugIns";
NSString* selectTypeMenuItemName = @"Select Type ...";