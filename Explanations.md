# Clarification #

The [MacFusion home page](http://www.sccs.swarthmore.edu/users/08/mgorbach/MacFusionWeb/) offers a primary introduction.

# Distinctions #

## Apple Mac OS and Finder ##

Questions relating to Mac OS and Finder should be addressed to Apple. Hot topics include:

  * .DS\_Store files
    * [Mac OS X 10.4: How to prevent .DS\_Store file creation over network connections](http://docs.info.apple.com/article.html?artnum=301711)
  * dot underscore files
    * [.\_](http://groups.google.com/group/MacFusion-devel/browse_frm/thread/67b3e3e141cdc162)

## MacFUSE, MacFusion and other applications ##
```
===========================================
|
|-- FUSE for Linux
|-- SSHFS
|
=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=
|
|-- MacFUSE kernel module
|-- SSHFS binary for MacFUSE
|
=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=
   |
   |-- MacFusion and plug-ins
       |-- CurlFtpFS (FTP)
       |-- EncFS
       |-- SSHFS (SSH/SFTP)
       |-- Xgrid FUSE (not yet implemented)
       |-- other plug-ins

=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=
   |
   |-- gDisk
   |-- iTunesFS
   |-- NTFS-3G for Mac OS X 
          and MacFUSE Tools
   |-- Secure Remote Disk
   |-- Xgrid FUSE
   |-- other applications

=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=.=^=
|
|||||| sshfs for Darwin (Mac OS X)

===========================================
```
(That's a fairly broad snapshot, sketched in May 2007; please, don't expect the representation above to be updated.)

MacFUSE and MacFusion are separate but closely related projects.

MacFUSE is the foundation upon which MacFusion runs.

[MacFusion](http://www.sccs.swarthmore.edu/users/08/mgorbach/MacFusionWeb/) is a [plug-in](http://code.google.com/p/macfusion/wiki/FileSystemsToImplement)-based graphical user interface (GUI) for [MacFUSE](http://googlemac.blogspot.com/2007/01/taming-mac-os-x-file-systems.html).

Bundled within the FTPFS.plugin [plug-in](http://code.google.com/p/macfusion/wiki/FileSystemsToImplement) to MacFusion is a curlftpfs-static binary for connections to FTP servers.

Bundled within the SSHFS.plugin [plug-in](http://code.google.com/p/macfusion/wiki/FileSystemsToImplement) to MacFusion is an sshfs-static binary for connections to SSH/SFTP servers.

sshfs.app may appear in the [MacFUSE downloads area](http://code.google.com/p/macfuse/downloads/list) but please note: whilst the sshfs-static binary within the bundle is supported, the sshfs.app (application bundle) in its entirety is an **[unsuppported](http://groups.google.com/group/macfuse-devel/browse_thread/thread/5dbb1af9eb4b3e06?tvc=2&fwc=1#) demo**.

Issues that relate to the sshfs-static binary -- not to MacFusion -- can be found/reported in the [MacFUSE issues area](http://code.google.com/p/macfuse/issues/list?can=2&q=sshfs&sort=priority&colspec=ID%20Type%20Status%20Priority%20Milestone%20Owner%20Summary).

(Issues that relate to the sshfs.app demo should **never** be reported.)

# Explanations #

Non-technical users will probably be baffled by those distinctions.

User-friendly explanations from MacFusion project members will be welcomed!



