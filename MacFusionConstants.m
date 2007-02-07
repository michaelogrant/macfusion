//
//  MacFusionConstants.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/18/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MacFusionConstants.h"

NSString* favoritesKeyName = @"Favorites";
NSString* favoritesFSTypeKeyName = @"FSType";
NSString* favoritesStoredObjectKeyName = @"StoredObject";
NSString* filesystemKeyName = @"Filesystem";
NSString* mountTimeoutKeyName = @"mountTimeout";
NSString* mountFaliureReasonKeyName = @"mountFaliureReason";

NSString* FuseFSMountFailedNotification = @"FuseFSMountFailed";
NSString* FuseFSMountedNotification = @"FuseFSMounted";
NSString* FuseFSUnmountedNotification = @"FuseFSUnmounted";

NSString* growlFSMountFailedNotification = @"Mount Faliure";
NSString* growlFSMountSuccessNotification = @"Mount Success";

NSString* FuseFSMountFaliureTimeout = @"Timeout";
NSString* FuseFSMountFaliureTaskEnded = @"Task Ended";
NSString* FuseFSMountFaliurePathIssue = @"Mountpoint Setup Failed";

NSString* FuseFSStatusUnmountedString = @"Unmounted";
NSString* FuseFSStatusWaitingToMountString = @"Waiting to Mount";
NSString* FuseFSStatusMountedString = @"Mounted";
NSString* FuseFSStatusMountFailedString = @"Mount Failed";