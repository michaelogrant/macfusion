/*
 *  ftp_askpass.h
 *  MacFusion
 *
 *  Created by Michael Gorbach on 3/31/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

// Modified from from askpass.c by Jan Lehnardt <jan@php.net>

NSString* FTPFSGetPasswordFromKeychain(const char *user, const char *server);
void  FTPFSSavePasswordToKeychain(const char *user, const char *server, const char *password);
NSString* FTPFSGetPasswordForUserAndServer(const char *user, const char *server);