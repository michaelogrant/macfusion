// Copyright (C) 2007 Google Inc.
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

// Keychain management by Jan Lehnardt <jan@php.net>

#define SSHFS_USER "SSHFS_USER"
#define SSHFS_SERVER "SSHFS_SERVER"

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

char *SSHFSGetPasswordForUserAndServer(const char *user, const char *server);
void SSHFSSavePasswordToKeychain(const char *user, const char *server, const char *password);

char *SSHFSGetPasswordForUserAndServer(const char *user, const char *server)
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
											 22, kSecProtocolTypeSSH, //port'n'type
											 kSecAuthenticationTypeDefault,
											 &passwordLength,
											 (void **) &password,
											 &item
											 );
	if(result == 0) {
		return password;
	}
	
	return "";
}

void SSHFSSavePasswordToKeychain(const char *user, const char *server, const char *password)
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
											 22, kSecProtocolTypeSSH, //port'n'type
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
												22, kSecProtocolTypeSSH, //port'n'type
												kSecAuthenticationTypeDefault,
												strlen(password),
												password,
												&item
												);
		CFRelease(item);
	}
}

int main() 
{
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFDictionaryRef dialogTemplate;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
	CFStringRef dialogText;
	int savePassword = 0;
	CFIndex passwordMaxSize;
	char *password;
	static void* keys;
	static void* values;
	
	//look for SSHFS_USER and SSHFS_SERVER in env
	const char *sshfs_user, *sshfs_server;
	sshfs_user = getenv(SSHFS_USER);
	sshfs_server = getenv(SSHFS_SERVER);
	
	int keychainEnable = 1;
	int freePassword = 0; // 0 = no, 1 = SecKeychainItemFreeContent(), 2 = free()
	
	if(!sshfs_user || !sshfs_server) 
	{
		keychainEnable = 0;
	} 
	else 
	{
		password = SSHFSGetPasswordForUserAndServer(sshfs_user, sshfs_server);
	}
	
	if(keychainEnable && strlen(password) > 0) 
	{
		freePassword = 1; // use SecKeychainItemFreeContent()
						  //done
	} 
	else 
	{
		
		CFBundleRef myBundle = CFBundleGetBundleWithIdentifier(CFSTR("org.mgorbach.MacFusion.SSHFS")); // we don't need to release this?
		CFURLRef myIconURL = CFBundleCopyResourceURL(myBundle,CFSTR("SSHFS"),CFSTR("icns"),NULL);
		
		const void* noKeychainKeys[] = {
			kCFUserNotificationAlertHeaderKey,
			kCFUserNotificationTextFieldTitlesKey,
			kCFUserNotificationAlternateButtonTitleKey,
			kCFUserNotificationIconURLKey
		};
		
		dialogText = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR("Enter SSH Password for user %s on server %s"), sshfs_user, sshfs_server);
		const void* noKeychainValues[] = {
			dialogText,
			CFSTR("Password"),
			CFSTR("Cancel"),
			myIconURL
		};
		
		const void* keychainKeys[] = {
			kCFUserNotificationAlertHeaderKey,
			kCFUserNotificationAlertMessageKey,
			kCFUserNotificationTextFieldTitlesKey,
			kCFUserNotificationCheckBoxTitlesKey,
			kCFUserNotificationAlternateButtonTitleKey,
			kCFUserNotificationIconURLKey
		};
		
		const void* keychainValues[] = {
			CFSTR("Password Needed"),
			dialogText,
			CFSTR("Password"),
			CFSTR("Save Password in Keychain"),
			CFSTR("Cancel"),
			myIconURL
		};
		
		if(keychainEnable) {
			keys = keychainKeys;
			values = keychainValues;
		} else {
			keys = noKeychainKeys;
			values = noKeychainValues;
		}
		
		dialogTemplate = CFDictionaryCreate(kCFAllocatorDefault,
											keychainKeys,
											keychainValues,
											sizeof(keychainKeys)/sizeof(*keychainKeys),
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
			return error;
		
		error = CFUserNotificationReceiveResponse(passwordDialog,
												  0,
												  &responseFlags);
		if (error)
			return error;
		
		button = responseFlags & 0x3;
		if (button == kCFUserNotificationAlternateResponse)
			return 1;
		
		if(keychainEnable) {
			savePassword = (responseFlags & CFUserNotificationCheckBoxChecked(0));
		}
		
		passwordRef = CFUserNotificationGetResponseValue(passwordDialog,
														 kCFUserNotificationTextFieldValuesKey,
														 0);
		
		passwordMaxSize = CFStringGetMaximumSizeForEncoding(CFStringGetLength(passwordRef),
															kCFStringEncodingUTF8);
		password = malloc(passwordMaxSize);
		CFStringGetCString(passwordRef,
						   password,
						   passwordMaxSize,
						   kCFStringEncodingUTF8);
		CFRelease(passwordDialog);
		freePassword = 2; // use free()
		
		if(keychainEnable && savePassword) {
			SSHFSSavePasswordToKeychain(sshfs_user, sshfs_server, password);
		}
	}
	
	printf("%s", password);
	
	if(freePassword == 1) {
		SecKeychainItemFreeContent(NULL, password);
	}
	
	if(freePassword == 2) {
		free(password);
	}
	
	return 0;
}
