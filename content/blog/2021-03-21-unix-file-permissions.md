---
title: An Intro to Unix File Permissions
date: 2021-03-21
tags:
- professional development
- linux
thumbnail: zig_zag_thumb.jpg
teaser: A brief, beginners' guide and cheat sheet to Unix file permissions.
---

_Unix file permissions are abstract and can be confusing, especially for those who aren't immersed in the surrounding concepts on a daily basis. This is a basic introduction and cheat sheet._

`ls -l file.txt` shows you `file.txt`'s permissions, among other things. But what does this stuff mean?

```txt
-rw-r--r--  1 mike  staff  804 Nov  1 20:09 file.txt
```

The first column -- `-rw-r--r--` -- represents the permissions access modes associated with `file.txt`.

In Unix-based operating systems, there are 3 things that can be done to a file:

1. `r`ead its content (represented by a `r`)
2. `w`rite to it and/or modify its content (represented by a `w`)
3. e`x`ecute it, as done when running a program (represented by a `x`)

Every file has attributes associated with...

1. owner permissions - What actions can the owner perform on the file?
2. group permissions - What actions can a user who is a member of a group that a file belongs to perform on the file?
3. other (world) permissions - What actions can all other users perform on the file?

Let's examine `ls -l file.txt`'s output again:

```txt
-rw-r--r--  1 mike  staff  804 Nov  1 20:09 file.txt
```

`file.txt`'s access modes -- `-rw-r--r--` -- can be subdivided into three groups of three, where each character in each group represents permissions pertaining to (1) the owner (the first group of three characters), (2) the group (the second group of three characters), and (3) the world (the third group of three characters):

1. `rw-` - the owner (`mike`) can `r`ead from and `w`rite to the file (but _cannot_ e`xecute` the file)
2. `r--` - the group (`staff`) can `r`ead the file (but _cannot_ `w`rite to the file or e`x`ecute the file)
3. `r--` - all others ("the world") can `r`ead the file (but _cannot_ `w`rite to the file or e`x`ecute the file)

## Changing permissions mode

The `chmod` command can be used to _change mode_.

`chmod` can be used in two ways:

1. symbolic mode
2. absolute mode

## Symbolic mode

Using `chmod` with symbolic mode allows setting permissions using a few operators:

| Symbol | Description |
|-|-|
| + | Adds permissions |
| - | Removes permissions |
| = | Sets permissions |

Symbolic mode leverages users flags, which specify the users for whom the permissions settings should be applied:

* `u` - owner permissions
* `g` - group permissions
* `o` - all other users
* `a` - all users

For example:

* `chmod u-x file.txt` removes owner e`x`ecute permissions from the owner
* `chmod o+wx file.txt` adds user `w`rite and e`x`ecute permissions to other users
* `chmod g=rx file.txt` sets group `r`ead and e`x`ecute

Note that if no users flag is provided, `a` (`a`ll users) is the default. For example, the following makes `file.txt` e`x`ecutable for all users:

```text
chmod +x file.txt
```

## Absolute mode

In contrast to symbolic mode, absolute mode allows the use of `chmod` with an octal notation system where a number from 0 through 7 represents permissions:

| Number | Ref | Permissions |
|-|-|-|
| 0 | `---` | no permissions |
| 1 | `--x` | execute |
| 2 | `--x` | write |
| 3 | `-wx` | write & execute (write (2) + execute (1) = 3) |
| 4 | `r--` | read |
| 5 | `r-x` | read & execute (read (4) + excute (1) = 5) |
| 6 | `rw-` | read & write (read (4) + write (2) = 6) |
| 7 | `rwx` | all permissions (read (4) + write (2) + execute (1) = 7) |

For example, let's review the original permissions on `file.txt`:

```txt
ls -l file.txt
-rw-r--r--  1 mike  staff  804 Nov  1 20:09 file.txt
```

Expressed as octal notation, `file.txt`'s permissions are `644`:

1. `rw-` (6) - the owner (`mike`) can `r`ead from and `w`rite to the file (but _cannot_ e`xecute` the file)
2. `r--` (4) - the group (`staff`) can `r`ead the file (but _cannot_ `w`rite to the file or e`x`ecute the file)
3. `r--` (4) - all others ("the world") can `r`ead the file (but _cannot_ `w`rite to the file or e`x`ecute the file)

To change `file.txt`'s permissions and add write access to the group (`staff`):

```txt
chmod 664 file.txt

ls -l file.txt
-rw-rw-r--  1 mike  staff  804 Nov  1 20:09 file.txt
```
