MacFusion
Michael Gorbach

	MacFusion is designed to be a general GUI for FUSE filesystems on the Mac OS. It is capable of loading plugins defining the filesystem it supports. Currently, only SSHFS is implemented, however new plugins will be available soon. The plugins follow a simple protocol as defined in the FuseFSProtocol header file. The plugins must also provide a UI class to show their configuration interface. The protocol for the UI is defined in the other protocol file.
	This is the first very early version of this software. It currently implements a favorites feature, as well as automatic mounted of selected favorites on start. There is also growl notification for failed mounts.