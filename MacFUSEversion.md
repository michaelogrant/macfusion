## I installed MacFUSE. Which version is installed? ##

  * View your receipt for the installation:

```
Finder | Go menu | 

/Library/Receipts/

then locate and select (single-click) 

     MacFUSE Core.pkg

File menu | Get Info
```

or

  * view the plist within that receipt; in Terminal, enter the following command:

```
more /Library/Receipts/MacFUSE\ Core.pkg/Contents/Info.plist
```

## I installed MacFUSE. Which version is running? ##

  * If you followed the prompt to **Restart** Mac OS after installing MacFUSE 0.3.0, then the running version should be the version shown in `Get Info` for its receipt (see above).
  * If you have overlooked a prompt to **Restart**, please Restart now.