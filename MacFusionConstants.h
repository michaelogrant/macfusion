//
//  MacFusionConstants.h
//  MacFusion
//
//  Created by Michael Gorbach on 1/18/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//
#import <Cocoa/Cocoa.h>

// key names
extern NSString* favoritesKeyName;
extern NSString* favoritesFSTypeKeyName;
extern NSString* favoritesStoredObjectKeyName;
extern NSString* filesystemKeyName;
extern NSString* mountTimeoutKeyName;
extern NSString* mountFaliureReasonKeyName;

// notification names
extern NSString* FuseFSMountFailedNotification;
extern NSString* FuseFSMountedNotification;
extern NSString* FuseFSUnmountedNotification;

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

// mount return enum
enum {
	FuseFSMountReturnOK,
	FuseFSMountReturnPathError,
};

// mount faliure reasons
extern NSString* FuseFSMountFaliureTimeout;
extern NSString* FuseFSMountFaliureTaskEnded;
extern NSString* FuseFSMountFaliurePathIssue;