---
title: Using TortoiseMerge on Linux with Bazaar
date: 2013-01-24
categories:
  - version control
tags:
  - Bzr
  - TortoiseMerge
thumbnailImagePosition: left
thumbnailImage: /img/wine-thumbnail.jpg
---

Having tried to fall in love with Meld and KDiff3, I've eventually gone back to my favourite merge tool, TortoiseMerge. It's actually very straightforward to get running on Linux.

<!--more-->

The basic steps are:

Install wine: `apt-get install wine`, or `yum install wine`.

Download the standalone version of TortoiseDiff from [Sourceforge](https://sourceforge.net/projects/tortoisesvn/files/OldFiles/Tools/) and extract `TortoiseMerge.exe` into ~/bin/.

Set up a new merge tool in your user configuration in Bazaar Explorer containing:

```
wine /home/pete/bin/TortoiseMerge.exe /base:{base} /theirs:{other} /mine:{this} /merged:{result}
```
