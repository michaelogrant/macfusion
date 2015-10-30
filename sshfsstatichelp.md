# This page is for technical users only! #
Options/help for future versions of sshfs-static may differ from those presented here. For the most up-to-date help on your sshfs-static, always

```
/Applications/MacFusion.app/Contents/PlugIns/SSHFS.plugin/Contents/Resources/sshfs-static -h
```

If your MacFusion is at a path other than `/Applications` then you should modify your command accordingly.

## sshfs-static in MacFusion 1.1 Beta 2 presents the following help ##
```
usage: sshfs [user@]host:[dir] mountpoint [options]

general options:
    -o opt,[opt...]        mount options
    -h   --help            print help
    -V   --version         print version

SSHFS options:
    -p PORT                equivalent to '-o port=PORT'
    -C                     equivalent to '-o compression=yes'
    -1                     equivalent to '-o ssh_protocol=1'
    -o reconnect           reconnect to server
    -o sshfs_sync          synchronous writes
    -o no_readahead        synchronous reads (no speculative readahead)
    -o sshfs_debug         print some debugging information
    -o cache=YESNO         enable caching {yes,no} (default: yes)
    -o cache_timeout=N     sets timeout for caches in seconds (default: 20)
    -o cache_X_timeout=N   sets timeout for {stat,dir,link} cache
    -o workaround=LIST     colon separated list of workarounds
             none             no workarounds enabled
             all              all workarounds enabled
             [no]rename       fix renaming to existing file (default: off)
             [no]nodelay      set nodelay tcp flag in ssh (default: on)
             [no]nodelaysrv   set nodelay tcp flag in sshd (default: on)
             [no]truncate     fix truncate for old servers (default: off)
             [no]buflimit     fix buffer fillup bug in server (default: on)
    -o idmap=TYPE          user/group ID mapping, possible types are:
             none             no translation of the ID space (default)
             user             only translate UID of connecting user
    -o ssh_command=CMD     execute CMD instead of 'ssh'
    -o ssh_protocol=N      ssh protocol to use (default: 2)
    -o sftp_server=SERV    path to sftp server or subsystem (default: sftp)
    -o directport=PORT     directly connect to PORT bypassing ssh
    -o transform_symlinks  transform absolute symlinks to relative
    -o follow_symlinks     follow symlinks on the server
    -o no_check_root       don't check for existence of 'dir' on server
    -o SSHOPT=VAL          ssh options (see man ssh_config)

FUSE options:
    -d   -o debug          enable debug output (implies -f)
    -f                     foreground operation
    -s                     disable multi-threaded operation

    -o allow_root          allow access to root

Available mount options:
    -o allow_other         allow access to others besides the user who mounted                             mounted the file system
    -o blocksize=<size>    specify block size in bytes of "storage"
    -o daemon_timeout=<s>  timeout in seconds for kernel calls to daemon
    -o debug               turn on debug information printing
    -o extended_security   turn on Mac OS X extended security (ACLs)
    -o fsid                set the second 32-bit component of the fsid
    -o fsname=<name>       set the file system's name
    -o init_timeout=<s>    timeout in seconds for the init method to complete
    -o iosize=<size>       specify maximum I/O size in bytes
    -o jail_symlinks       contain symbolic links within the mount
    -o kill_on_unmount     kernel will send a signal (SIGKILL by default) to the
                           daemon after unmount finishes
    -o noapplespecial      ignore Apple Double (._) and .DS_Store files entirely
    -o noauthopaque        set MNTK_AUTH_OPAQUE in the kernel
    -o noauthopaqueaccess  set MNTK_AUTH_OPAQUE_ACCESS in the kernel
    -o nobrowse            set MNT_DONTBROWSE in the kernel
    -o nolocalcaches       meta option equivalent to noreadahead,noubc,novncache
    -o noping_diskarb      do not ping Disk Arbitration (pings by default)
    -o noreadahead         disable I/O read-ahead behavior for this file system
    -o nosynconclose       disable sync-on-close behavior (enabled by default)
    -o nosyncwrites        disable synchronous-writes behavior (dangerous)
    -o noubc               disable the unified buffer cache for this file system
    -o novncache           disable the vnode name cache for this file system
    -o subtype=<num>       set the file system's subtype identifier
    -o volname=<name>      set the file system's volume name

    -o hard_remove         immediate removal (don't hide files)
    -o use_ino             let filesystem set inode numbers
    -o readdir_ino         try to fill in d_ino in readdir
    -o direct_io           use direct I/O
    -o kernel_cache        cache files in kernel
    -o [no]auto_cache      enable caching based on modification times
    -o umask=M             set file permissions (octal)
    -o uid=N               set file owner
    -o gid=N               set file group
    -o entry_timeout=T     cache timeout for names (1.0s)
    -o negative_timeout=T  cache timeout for deleted names (0.0s)
    -o attr_timeout=T      cache timeout for attributes (1.0s)
    -o ac_attr_timeout=T   auto cache timeout for attributes (attr_timeout)
    -o intr                allow requests to be interrupted
    -o intr_signal=NUM     signal to send on interrupt (30)

    -o max_write=N         set maximum size of write requests
    -o max_readahead=N     set maximum readahead
    -o async_read          perform reads asynchronously (default)
    -o sync_read           perform reads synchronously
[grahamperrin:~] gjp22% 
```

# General #

A [comment](http://groups.google.com/group/macfuse-devel/msg/4860230d6967dc3b) from Amit Singh:

> …OS X and Linux are quite different platforms, and MacFUSE shares
> pretty much nothing (except the user-kernel interface definition)
> with Linux FUSE. So, the semantics of certain things (blocksize,
> for example) aren't quite the same for both.

# About the options #

## allow\_root ##

Amit  [explains](http://code.google.com/p/macfuse/issues/detail?id=178&can=2&q=#c11):

> 2. … blanket denial applies to the root user too. Even if you are root, you can't enter a MacFUSE volume unless you mounted it as root. Otherwise, it would make it easier for a user space file system to hang/mislead any root owned system processes that happen to encounter the volume. This behavior has always been like this and is an architectural decision.