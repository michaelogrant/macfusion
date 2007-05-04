//
//  main.m
//  MacFusion
//
//  Created by Michael Gorbach on 1/14/07.
//  Copyright Michael Gorbach 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdio.h>     /* standard I/O functions                         */
#include <unistd.h>    /* standard unix functions, like getpid()         */
#include <sys/types.h> /* various type definitions, like pid_t           */
#include <signal.h>    /* signal name macros, and the signal() prototype */

void catch_sigpipe(int sig_num)
{
	/* re-set the signal handler again to catch_int, for next time */
	signal(SIGPIPE, catch_sigpipe);
	/* and print the message */
	NSLog(@"Sigpipe hit");
	fflush(stdout);
}

int main(int argc, char *argv[])
{
	signal(SIGPIPE, catch_sigpipe);
	return NSApplicationMain(argc,  (const char **) argv);
}
