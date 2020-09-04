---
title: NW.js Chromium data-path
date: 2015-04-09
tags:
- nwjs
- node-webkit
- nodejs
- chromium
thumbnail: block_island_thumb.png
teaser: How to ensure against persistant cookies and local storage data between installs of an nw.js app.
---

[NW.js](http://nwjs.io/) (formerly node-webkit) offers a platform through which desktop applications can be authored using Node.js and web technologies, like Chromium.

<b>Problem</b>:

But how can it be ensured that user data doesn't persist between fresh installations of a NW.js application? For example, consider the following:

1. user installs `SOME_NW_APP`.
2. `SOME_NW_APP` leverages cookies and local storage.
3. NW.js writes the cookies/local storage data to `~/Library/Application\ Support/SOME_NW_APP` on Mac OS and `C:\Users\%USERNAME%\AppData\Local\Chromium\User Data\Default` on Windows 8.
4. user deletes the app by trashing the `/Applications/SOME_NW_APP.app` file in Mac OS or running the associated uninstaller in Windows 8, assuming the installation provided an uninstaller.
5. user re-installs `SOME_NW_APP`
6. `SOME_NW_APP` retains cookies and local storage data from its first installation.

<b>Solution</b>:

The NW.js [manifest](https://github.com/nwjs/nw.js/wiki/Manifest-format) provides a mechanism through which configuration arguments can be passed to Chromium, including `--user-data`, which defines the path at which cookies and local storage data are stored. By explicitly setting this path, we can ensure that it's properly removed on uninstall.

Example manifest:

```
{
  "name": "SOME_NW_APP",
  "description": "Some description",
  "version": "0.0.3",
  "main": "src/index.html",
  "chromium-args": "--data-path='data/'"
}
```

## Mac OS

In Mac OS, an application built via the preceding manifest will store cookie/local storage data in `SOME_NW_APP.app/data`, thus ensuring that the `data` directory is deleted when `SOME_NW_APP.app` is trashed.

Note, though, this assumes the user running `SOME_NW_APP.app` has the necessary write permissions. Permissions can be a problem when `/Applications` is owned by root, `SOME_NW_APP.app` lives in `/Applications`, and the user running `SOME_NW_APP.app` does not have write permissions, as is often the case on Mac OS. Such a scenario prevents cookies and local storage items from being properly saved. See [my comment here](https://github.com/nwjs/nw.js/issues/1175#issuecomment-112122560) for more information.

## Windows

In Windows, a tool such as [nsis](/blog/node-webkit-app-windows-installer/) can be used to build an installer as well as an uninstaller; the uninstaller can ensure that all `data` files are deleted.

Example nsi uninstaller section:

```nsis
Section "Uninstall"
  RMDir '"$INSTDIR\Local Storage"'
  RMDir "$INSTDIR\locales"

  Delete "$INSTDIR\data\Cache\*"
  Delete "$INSTDIR\data\Cache\index-dir\*"
  RMDir "$INSTDIR\data\Cache\index-dir"
  RMDir "$INSTDIR\data\Cache"

  Delete "$INSTDIR\data\*"
  RMDir "$INSTDIR\data\Local Storage"

  RMDir "$INSTDIR\data"
SectionEnd
```
