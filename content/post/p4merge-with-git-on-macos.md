
---
title: p4merge for conflict-resolution on macOS
date: 2018-11-20
categories:
  - development
tags:
  - Git
  - macOS
thumbnailImagePosition: left
thumbnailImage: /images/peace-thumbnail.jpg
---

Using Git on macOS is largely a positive experience, other than (in my opinion) the
out of the box experience with merge tools. With my recent
[merge](https://github.com/Homebrew/homebrew-cask/commit/12a256663370207ff198d4fdbcef53e96e06a21e)
to Homebrew Cask you can use p4merge with no extra work.

<!--more-->

# TL;DR

Assuming you're already using [Homebrew](https://brew.sh/), just install `p4v`
```
brew cask install p4v
```

and then configure `p4merge` as the default mergetool
```
git config --global merge.tool p4merge
```

Now whenever you run `git mergetool`, you'll be presented with `p4merge`.

# How does it work?

My change to the Homebrew package basically just inject a simple wrapper script
like below
{{< codeblock "wrapper.sh" "BASH" "" >}}
#!/bin/bash
set -euo pipefail
COMMAND=$(basename "$0")
exec "/Applications/${COMMAND}.app/Contents/MacOS/${COMMAND}" $@ 2> /dev/null
{{< /codeblock >}}
for each of the Perforce applications included in the installer.

This wrapper script basically allows the embedded Qt installation to detect
the correct path to load itself from. If you try a symlink, it will see its
path as `/usr/local/bin`, and try and load Qt from there, which won't work.

With the wrappers installed, you no-longer need to write any of your own,
or set fiddly git config to make it work.