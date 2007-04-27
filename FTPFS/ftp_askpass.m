/*
 *  ftp_askpass.c
 *  MacFusion
 *
 *  Created by Michael Gorbach on 3/31/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */

#include "ftp_askpass.h"

#pragma mark Password Functions

NSString* FTPFSGetPasswordFromKeychain(const char *user, const char *server)
{
	OSStatus result;
	char *password;
	UInt32 passwordLength;
	SecKeychainItemRef item = NULL;
	
	result = SecKeychainFindInternetPassword(
											 NULL, //default keychain
											 strlen(server), // servername length
											 server,
											 0, NULL, // security domain
											 strlen(user), 
											 user,
											 0, NULL, //path
											 21, kSecProtocolTypeFTP, //should this be a FTP, FTPAccount or FTPProxy? Who knows?
											 kSecAuthenticationTypeDefault,
											 &passwordLength,
											 (void **) &password,
											 &item
											 );
	if(result == 0) {
		NSString* passwordString = [NSString stringWithCString:password length:passwordLength];
		SecKeychainItemFreeContent(NULL, password);
		return passwordString;
	}
	
	return @"";
}

void FTPFSSavePasswordToKeychain(const char *user, const char *server, const char *password)
{
    OSStatus result;
    SecKeychainItemRef item;
	
    result = SecKeychainFindInternetPassword(
											 NULL, //default keychain
											 strlen(server), // servername length
											 server,
											 0, NULL, // security domain
											 strlen(user), 
											 user,
											 0, NULL, //path
											 21, kSecProtocolTypeFTP, //port'n'type
											 kSecAuthenticationTypeDefault,
											 0,
											 NULL,
											 &item
											 );
	if (result == noErr) {
		//update info
		SecKeychainAttribute attributes;
		SecKeychainAttributeList attributesList;
		
		attributes.tag = kSecAccountItemAttr;
		attributes.length = strlen(user);
		attributes.data = (char *)user;
		
		attributesList.count = 1;
		attributesList.attr = &attributes;
		
		result = SecKeychainItemModifyContent(item, &attributesList, strlen(password), (void *)password);
		CFRelease(item);
		
	} else {
		//add info
		result = SecKeychainAddInternetPassword(
												NULL, //default keychain
												strlen(server), // servername length
												server,
												0, NULL, // security domain
												strlen(user), 
												user,
												0, NULL, //path
												21, kSecProtocolTypeFTP, //port'n'type
												kSecAuthenticationTypeDefault,
												strlen(password),
												password,
												&item
												);
		CFRelease(item);
	}
}

NSString* FTPFSGetPasswordForUserAndServer(const char *user, const char *server)
{
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFDictionaryRef dialogTemplate;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef dialogText;
	int savePassword = 0;
	NSString* password;
	
	
	password = FTPFSGetPasswordFromKeychain(user, server);


	if([password length] > 0)
	{
		return password;
	}
	
	CFBundleRef myBundle = CFBundleGetBundleWithIdentifier(CFSTR("org.mgorbach.MacFusion.FTPFS")); // we don't need to release this?
    CFURLRef myIconURL = CFBundleCopyResourceURL(myBundle,CFSTR("FTPFS"),CFSTR("icns"),NULL);
	
	dialogText = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR("Enter FTP Password for user %s on server %s"), user, server);
	
    const void* keys[] = {
		kCFUserNotificationAlertHeaderKey,
		kCFUserNotificationAlertMessageKey,
		kCFUserNotificationTextFieldTitlesKey,
		kCFUserNotificationCheckBoxTitlesKey,
		kCFUserNotificationAlternateButtonTitleKey,
		kCFUserNotificationIconURLKey
    };
	
    const void* values[] = {
		CFSTR("Password Needed"),
		dialogText,
		CFSTR("Password"),
		CFSTR("Save Password in Keychain"),
		CFSTR("Cancel"),
		myIconURL
    };
	
    dialogTemplate = CFDictionaryCreate(kCFAllocatorDefault,
                                        keys,
                                        values,
                                        sizeof(keys)/sizeof(*keys),
                                        &kCFTypeDictionaryKeyCallBacks,
                                        &kCFTypeDictionaryValueCallBacks);
    CFRelease(myIconURL);
	
    passwordDialog = CFUserNotificationCreate(kCFAllocatorDefault,
                                              0,
                                              kCFUserNotificationPlainAlertLevel
											  |
                                              CFUserNotificationSecureTextField(0),
                                              &error,
                                              dialogTemplate);
	
    if (error)
		return @"";
	
    error = CFUserNotificationReceiveResponse(passwordDialog,
                                              0,
                                              &responseFlags);
    if (error)
		return @"";
	
    button = responseFlags & 0x3;
    if (button == kCFUserNotificationAlternateResponse)
	{
		CFRelease(passwordDialog);
		return @"";
	}
	
	savePassword = (responseFlags & CFUserNotificationCheckBoxChecked(0));
	password = (NSString*)CFUserNotificationGetResponseValue(passwordDialog,
                                                     kCFUserNotificationTextFieldValuesKey,
                                                     0);
	[password retain];
    CFRelease(passwordDialog);
	
    if(savePassword) {
		FTPFSSavePasswordToKeychain(user, server, [password cString]);
    }
	
	return [password autorelease];
}
