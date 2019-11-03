---
title: Creating a Windows Installer for a node-webkit App on Mac OS
date: 2014/09/25
tags: node, node-webkit, installer, automation
thumbnail: eyeball_hand_thumb.png
teaser: How to create a Windows app installer on the Mac OS command line using makensis.
---

[node-webkit](https://github.com/rogerwang/node-webkit) provides a powerful path through which Linux, Windows, and Mac OS desktop applications can be authored using HTML5 and Node.js web technologies. [grunt-node-webkit-builder](https://github.com/mllrsohn/grunt-node-webkit-builder) offers a tool through which a node-webkit application can be compiled to distributable directories. But how can an automated build process bundle the MS Windows files in an application installer in a headless continuous integration environment, or from the command line?

[makensis](http://nsis.sourceforge.net/Main_Page) provides a solution. The tool can be used on Linux, though this overview focuses on Mac OS.

Install `makensis` on Mac OS using [homebrew](http://brew.sh/):

```
brew install nsis
```

A basic `windows_installer.nsi` file:

```nsi
!define PRODUCT_NAME "Your App Name"

Name "${PRODUCT_NAME}"

# define the resulting installer's name:
OutFile "your_app_installer.exe"

# default section start
Section

  # define the path to which the installer should install
  SetOutPath $INSTDIR

  # specify the files to go in the output path
  # these are the Windows files produced by grunt-node-webkit-builder
  File path/to/build/win/your-app-name/ffmpegsumo.dll
  File path/to/build/win/your-app-name/icudt.dll
  File path/to/build/win/your-app-name/libEGL.dll
  File path/to/build/win/your-app-name/libGLESv2.dll
  File path/to/build/win/your-app-name/nw.pak
  File path/to/build/win/your-app-name/your-app-name.exe

  # define the uninstaller name
  WriteUninstaller $INSTDIR\your_app_uninstaller.exe

  # create a shortcut named 'your_app' in the start menu
  # point the shortcute at your-app-name.exe
  CreateShortCut "$SMPROGRAMS\your_app.lnk" "$INSTDIR\your-app-name.exe"

SectionEnd

# create a section to define what the uninstaller does
Section "Uninstall"

  # delete the uninstaller
  Delete $INSTDIR\your_app_uninstaller.exe

  # delete the installed files
  Delete $INSTDIR\ffmpegsumo.dll
  Delete $INSTDIR\icudt.dll
  Delete $INSTDIR\libEGL.dll
  Delete $INSTDIR\libGLESv2.dll
  Delete $INSTDIR\nw.pak
  Delete $INSTDIR\your-app-name.exe
  Delete $SMPROGRAMS\your_app.lnk
  Delete $INSTDIR

SectionEnd
```

And run the `nsi` file to generate the `your_app_installer.exe`:

```
$ makensis windows_installer.nsi
```

Now, `your_app_installer.exe` can be distributed to users, thus offering a simple, stream-lined process through which `your-app` can be installed.
