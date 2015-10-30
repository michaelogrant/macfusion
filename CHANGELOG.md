# Changes and feature additions to MacFusion and components bundled therein #

**Note**: the _[MacFUSE changelog](http://code.google.com/p/macfuse/wiki/CHANGELOG)_ appears in its own project area.

### deferred ###
  * [About MacFusion window and Finder | Get Info are more descriptive](http://code.google.com/p/macfusion/issues/detail?id=197); version strings and other changes to info.plist
  * random issues with [unpredictable third party applications + sleep/wake preferences + change of location whilst awake (in combination with each other)](http://code.google.com/p/macfusion/issues/detail?id=25#c21): discussion and testing ongoing
  * [URL for software updates corrected](http://code.google.com/p/macfusion/issues/detail?id=198&can=1&q=info.plist); users of MacFusion release 1.1 will probably need to update manually

# MacFusion 1.2 Beta 3 — requires MacFUSE Core 0.4.0 #
**[2007-07-16](http://code.google.com/p/macfusion/downloads/list)**

  * notifications from MacFUSE are watched and logged by MacFusion ([revision 286](https://code.google.com/p/macfusion/source/detail?r=286) in Subversion, 2007-07-04)

## MacFusion nightly 20070704 [revision 284](https://code.google.com/p/macfusion/source/detail?r=284) ##
2007-07-04, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. [Custom port number for SSH favourite](http://code.google.com/p/macfusion/issues/detail?id=218) is saved when MacFusion quits.
  1. Fixes for [failed to access volume icon file (2)](http://code.google.com/p/macfusion/issues/detail?id=211) error.
  1. [MacFusion log line spacing and line endings](http://code.google.com/p/macfusion/issues/detail?id=221) are improved.

## MacFusion nightly 20070627 [revision 279](https://code.google.com/p/macfusion/source/detail?r=279) ##
2007-06-27, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. FTP Extra Options (Advanced) **-o ftpfs\_debug=3 -d -v** for a troublesome connection will now result in appropriate debug information in MacFusion logs.
  1. Improved/renewed [compatibility for users of MacPorts](http://code.google.com/p/macfusion/issues/detail?id=213).

## MacFusion 1.2 Beta 2 ##
2007-06-23, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. FTP [authentication behaviour](http://code.google.com/p/macfusion/issues/detail?id=210) is restored.
  1. Icon naming changes.
  1. Pre-empting [issues with some FTP servers](http://code.google.com/p/macfusion/issues/detail?id=152), curlftpfs will by default use PASV (will not first attempt EPSV).

## MacFusion 1.2 Beta 1 — requires MacFUSE Core 0.4.0 ##
2007-06-21, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. [Advanced options for CurlFtpFS](http://code.google.com/p/macfusion/issues/detail?id=178) (FTP).
  1. API improvements for easier loading and saving of file systems ([revision 263](https://code.google.com/p/macfusion/source/detail?r=263) in Subversion, 2007-06-17).
  1. [Compatible with case-sensitive file systems](http://code.google.com/p/macfusion/issues/detail?id=153) ([revision 253](https://code.google.com/p/macfusion/source/detail?r=253) in Subversion, 2007-06-04).
  1. **Compatible with MacFUSE 0.4.0** ([revision 260](https://code.google.com/p/macfusion/source/detail?r=260) in Subversion, 2007-06-09).
  1. [favorites for a plug-in that is absent](http://code.google.com/p/macfusion/issues/detail?id=193) are preserved but not loaded.
  1. Fix for linker warnnings and build problems ([revision 232](https://code.google.com/p/macfusion/source/detail?r=232) in Subversion, 2007-05-23).
  1. Fix to description string generation for network filesystems ([revision 267](https://code.google.com/p/macfusion/source/detail?r=267) in Subversion, 2007-06-18).
  1. FTP connection improved thanks to version 0.9.1 of curlftpfs (previously 0.9.0).
  1. GUI is improved ([revision 261](https://code.google.com/p/macfusion/source/detail?r=261) in Subversion, 2007-06-11).
  1. Header files are properly copied into the final product, with their "role" set to public ([revision 233](https://code.google.com/p/macfusion/source/detail?r=233) in Subversion, 2007-05-23).
  1. Icon support for FTP and SSH ([revision 263](https://code.google.com/p/macfusion/source/detail?r=263) in Subversion, 2007-06-17).
  1. Minor fixes ([revision 263](https://code.google.com/p/macfusion/source/detail?r=263) in Subversion, 2007-06-17).
  1. Refactored: SSHFS and FTPFS now inherit from the same class (MFNetworkFS); non-network file system should inherit from MFFilesystem ([revision 261](https://code.google.com/p/macfusion/source/detail?r=261) in Subversion, 2007-06-11).
  1. Renamed some files and classes with prefix ([revision 263](https://code.google.com/p/macfusion/source/detail?r=263) in Subversion, 2007-06-17).

# MacFusion 1.1 — requires MacFUSE Core 0.3.0 (not compatible with MacFUSE Core 0.4.0) #
**[2007-05-22](http://code.google.com/p/macfusion/downloads/list)**

  1. Compatible with standard [Fink](http://pdb.finkproject.org/pdb/package.php/fuse) and [MacPorts](http://www.macports.org/) installations; MacFusion (curlftpfs and sshfs plug-ins) will recognise [alternate paths to libfuse](http://code.google.com/p/macfusion/issues/detail?id=90).
  1. Contextual menu for the Favorites view.
  1. Contextual menu option: [duplicate an existing favourite](http://code.google.com/p/macfusion/issues/detail?id=89).
  1. Contributors to code are credited in an `authors` file.
  1. Dependency checking: MacFusion should warn _once_ if it encounters a [version of MacFUSE that is untested with the running version of MacFusion](http://code.google.com/p/macfusion/issues/detail?id=69).
  1. Favorites window floats. Window can be minimised. Window is [lost](http://code.google.com/p/macfusion/issues/detail?id=122) only when Exposé is active.
  1. Headers are packaged in `MacFusion.app` bundle under `headers`.
  1. Log is written to [~/Library/Logs/MacFusion.log](http://code.google.com/p/macfusion/issues/detail?id=93) where it is readable by Apple's Console utility.
  1. [Log window pane](http://code.google.com/p/macfusion/issues/detail?id=80) resizes in harmony with window frame.
  1. Log window scrolls automatically if nothing else is selected.
  1. Logging API improved, using plug-ins to guarantee properly ordered presentation of notifications.
  1. Logging from the macfusion core should now go directly to the log window and log file instead of the console.
  1. OK button fixed for saving changes to [paths](http://code.google.com/p/macfusion/issues/detail?id=88), [sshfs options](http://code.google.com/p/macfusion/issues/detail?id=78) and [other fields in the Edit sheet of the Favourites window](http://code.google.com/p/macfusion/issues/detail?id=135).
  1. Plug-ins link against MacFusion.app using `-bundle_loader`.
  1. Preferences are [written to ~/Library/Preferences/org.mgorbach.MacFusion.plist](http://code.google.com/p/macfusion/issues/detail?id=38) at time of preference.
  1. Processes from sshfs are now correctly terminated on unmount (using SIGKILL) if we are using -odebug in the advanced flags.
  1. [Selection changing discontinuously](http://code.google.com/p/macfusion/issues/detail?id=77) fixed.
  1. Quick Mount window floats.
  1. Sparkle [checks for updates to MacFusion application bundle (only)](http://code.google.com/p/macfusion/issues/detail?id=55) are preferred by default for first-time users. Preference window at first launch [should no longer be obscured](http://code.google.com/p/macfusion/issues/detail?id=10).
  1. Sparkle updating is now enabled and linked to the appcast of macfusion off `www.iusethis.com`.
  1. UI improvements.

## MacFusion 1.1 Beta2 — required MacFUSE Core 0.3.0 (not compatible with MacFUSE Core 0.4.0) ##
2007-05-11, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. Compatible with [MacFUSE](http://code.google.com/p/macfuse/) 0.3.0.
  1. [Extra Options (Advanced) field added to Favourites and Quick Connect dialogues for SSHFS](http://code.google.com/p/macfusion/issues/detail?id=28).
  1. Fix for most situations in which [volume mount points are not removed following a connection failure](http://code.google.com/p/macfusion/issues/detail?id=6).
  1. Fix for a [MacFusion notification presented via Growl that could be misleading in situations such as mount failure or user error](http://code.google.com/p/macfusion/issues/detail?id=12&).
  1. `allow_root` is ~~now enabled by default~~ [no longer perceived as a possible preference](http://code.google.com/p/macfusion/issues/detail?id=16#c7).
  1. [Log menu and window](http://code.google.com/p/macfusion/issues/detail?id=14) added to MacFusion. Less [dependence upon Growl](http://code.google.com/p/macfusion/issues/detail?id=35).
  1. [SSHFS latency](http://code.google.com/p/macfusion/issues/detail?id=12) improved (sshnodelay.so).
  1. Verification (closure) of [MacFUSE issue 164](http://code.google.com/p/macfuse/issues/detail?id=164) has been recommended.

## MacFusion 1.01 B1 ##
2007-04-27, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  1. Bugs with saving of SSH and FTP passwords should be mostly squashed.
  1. `Follow symlinks` is now on by default
    * [if anyone really needs a switch for this, I can add one](http://code.google.com/p/macfusion/issues/list)
    * it is unlikely that anyone will need to turn it off.
  1. Fixes for minor GUI bugs.
  1. Includes new version of SSHFS binary
    * sshfs-static here is equivalent to the sshfs-static bundled in version 0.2.0 of [sshfs.app](http://code.google.com/p/macfuse/wiki/MACFUSE_FS_SSHFS)
    * should fix issues such as [this one involving Microsoft Word 2004](http://code.google.com/p/macfusion/issues/detail?id=5).

## MacFusion 1.0 — required MacFUSE Core 0.2.5 (not compatible with MacFUSE Core 0.3.0 and beyond) ##
2007-04-22, [deprecated](http://code.google.com/p/macfusion/downloads/list?can=4&q=&colspec=Filename+Summary+Uploaded+Size+DownloadCount)

  * this release coincided with the launch of the [MacFusion home page](http://www.sccs.swarthmore.edu/users/08/mgorbach/MacFusionWeb/).




