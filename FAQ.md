# FAQ #

## Updates to MacFUSE and MacFusion ##

If an [update to MacFUSE](http://code.google.com/p/macfuse/wiki/CHANGELOG) appears before an [update to MacFusion](http://code.google.com/p/macfusion/wiki/CHANGELOG), should I refrain from updating my MacFUSE installation?

  * At launch time, MacFusion performs MacFUSE-oriented checks
    * if your **only** use of MacFUSE is for MacFusion, await advice from MacFusion developers before updating or upgrading MacFUSE
    * if MacFusion is not tested with a particular version of MacFUSE, MacFusion may (properly) not launch
    * if a security issue arises, exceptional action may be advised.

Unless advised otherwise, please:
  1. set the MacFusion preference to [√] Check for Updates on Startup
  1. wait for MacFusion to announce recommended updates.
    * MacFusion uses Sparkle technology to automate these announcements and installations.

Will MacFusion's Sparkle configuration announce updates to MacFUSE as well as MacFusion?

  * —

## I launched MacFusion but I can't see it running. Where is it? ##
![http://blog.nicolargo.com/wp-content/uploads/2007/05/macfusionmenu.png](http://blog.nicolargo.com/wp-content/uploads/2007/05/macfusionmenu.png)
  * MacFusion 1 is a menu extra without a Dock icon
    * look for the grey globe+arrows icon in your menu bar
    * probably to the left of other icons with which you're familiar
    * the [menu extra icon and menus in general](http://code.google.com/p/macfusion/issues/list?can=2&q=label%3Amenus+OR+label%3AMenuExtraIcon&sort=priority&colspec=ID+Type+Status+Priority+Milestone+Owner+Summary) are discussed amongst the other issues.
  * [Dock and menu extra preferences](http://code.google.com/p/macfusion/issues/detail?id=156) may appear in a future release.

## How do I install, disable or remove plug-ins for MacFusion? ##
Recommended:
  * file at path `/Library/Application Support/MacFusion/plugins/`

Alternatively, in the home directory:
  * file at path `~/Library/Application Support/MacFusion/plugins/`

Functional but not recommended, within the MacFusion application bundle:
  * Finder | select MacFusion | File menu | Get Info | Plug-Ins: …
    * plug-ins added in this way may not be respected during udpates/upgrades to MacFusion

After using Finder to manipulate any plug-in:
  1. Quit from MacFusion
  1. re-launch MacFusion.

## How does MacFusion differ from MacFUSE? Are there complements and alternatives? ##

  * In this wiki we have some [explanations](http://code.google.com/p/macfusion/wiki/Explanations).
  * If any explanation is lacking, please do not hesitate to [request an improvement](http://code.google.com/p/macfusion/issues/list?can=2&q=Type:Enhancement&sort=priority&colspec=ID%20Type%20Status%20Priority%20Milestone%20Owner%20Summary).

## Where can I learn more about permissions in the context of MacFUSE and MacFusion? ##

  * On 9th May 2007 Amit Singh offered [advice to the macfuse-devel Google Group](http://groups.google.com/group/macfuse-devel/browse_thread/thread/8ddca0a74765f200).





