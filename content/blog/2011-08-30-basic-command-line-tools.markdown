---
title: Basic Command Line Tools
date: 2011/08/30
tags:
- bash
- command line
- notes
thumbnail: ./images/thumbnails/prompt_thumb.png
teaser: Some beginner's notes; collected for a recently-hired junior developer.
---

A co-worker expressed interest in learning more Unix command line operations. This collection seeks to supplement his basic knowledge with some additional tips and tools.

## Searching Source Code

* ack can be downloaded at betterthangrep.com and is a great, free tool for searching a project’s source code. Usage: ack string will return the relative paths to all the files containing the matched string, the line on which the string is found with the match highlighted, and the line number on which the match lives, all while ignoring those files contained within .git or .svn directories.
* <code>ack --js searchtext</code> will perform a search on all *.js files.
* If you still prefer grep, the following would return the relative paths to all the files in which the text “string” is found: <code>grep -rl string . | grep -v \.svn</code>, excluding files in .svn directories.

## Diffing

* <code>diff -rq some_directory some_other_directory</code> will recursively diff all files in some_directory and some_other_directory, printing the files containing any descrepencies to the terminal.
* <code>diff file_one file_two</code> will output to the terminal all instances of descrepencies between file_one and file_two, as well as outputing the line/column number in which the differences exist.
* Alternatively, colordiff is a tool which provides colorized ouput to diff. If you’re using homebrew, colordiff can be installed with brew install colordiff. See colordiff man for usage.

## Miscellaneous Operations on Files

* <code>cat filename</code> will output the contents of filename to the terminal.
* <code>less filename</code> provides a much better way to inspect large files from the command line. It outputs only a full screen view of a file’s contents. Use j and k to scroll up and down. b and f navigate a full screen up and down. Use /pattern to search for the text pattern.
* <code>cat file1 >> file2</code> will write the contents of file1 to file2.
* <code>touch filename</code> will create a file named filname within the current directory.
* Once installed, tree produces a depth-indented listing of files.
* <code>chmod 760 filename</code> changes the permissions on filename to 760.

## Maintainenance, Monitoring, and Debugging

* <code>ps xa</code> lists all the running processes on your machine.
* <code>ps xa | grep java</code> will will check if a process named java is running. kill -9 xxxx, where xxxxx is the process id, will kill the java process. This is useful if something has frozen.
* top is a system monitor tool that produces a frequently-updated list of processes. By default, the processes are ordered by percentage of CPU usage.
* <code>tail -f log_file_name</code> outputs the log file’s content to the terminal, which is helpful when troubleshooting code such as PHP or Apache.
* Cheat is a RubyGem that provides command-line access to simple cheat sheets, not unlike a simplified, user-edited man page. An out-of-the-box Cheat installation provides a few basic starter cheat sheets which can be edited and extended easily. It’s also relatively easy to add your own additional cheat sheets. Example Usage: cheat html.
* Most commands have a -help option which will list a command’s arguments and options. Example: cd -help.
* Similarly, man provides more detailed documentation. Example: man mysqldump.

## Working With a Server

* <code>ssh username@hostname.com</code> provides ssh acess.
* Similarly, <code>ftp username@hostname.com</code> and <code>sftp username@hostname.com</code> provide ftp and sftp access, respectively.
* <code>scp /path/to/local/file username@hostname:path/to/copy/to</code> can be used to copy files to a server over ssh.
* Similarly, <code>scp username@hostname:/path/to/remote/file /local/path/to/copy/to/</code> copies a file from a server to your local machine.
* wget can be used to retrieve content from a web server. Example: <code>wget http://hostname.com/somefile.zip</code> will download somefile.zip from http://hostname.com.
* Similarly, <code>curl -O http://hostname.com/download.tar.gz</code> will download download.tar.gz
