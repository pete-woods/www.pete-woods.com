---
title: Converting a CVS repository on Sourceforge to a Git repository
date: 2010-10-01
categories:
  - version control
tags:
  - Git
  - CVS
thumbnailImagePosition: left
thumbnailImage: /images/chrysalis-thumbnail.jpg
---

Here's a script I came up with to extract any project's CVS repository from Sourceforge and convert it into a Git repository. To run it you'll need Git and Subversion installed on your machine.

<!--more-->

{{< codeblock "sf-cvs2git.sh" "BASH" >}}
#!/bin/bash

set +e
set +u

DEST=$PWD
PROJECT=$1
WORKSPACE=/tmp/sf-cvs2git.$$
ORIG=$PROJECT-orig
CVS=$PROJECT-cvs
GIT=$PROJECT

# Trap ctrl-c, etc
trap "rm -rf $WORKSPACE; exit" INT TERM EXIT

# Create a workspace for ourselves
mkdir $WORKSPACE
cd $WORKSPACE

# Copy the whole CVS repository
rsync -av rsync://$PROJECT.cvs.sourceforge.net/cvsroot/$PROJECT/ $ORIG

# Overlay all of the CVS modules on top of each other
mkdir -p $CVS/all
mv $ORIG/CVSROOT $CVS
mv $ORIG/* $CVS/all

# Get the cvs2git tool
svn co --username=guest --password="" http://cvs2svn.tigris.org/svn/cvs2svn/trunk cvs2svn

# Extract the CVS repository into the fast-export format
./cvs2svn/cvs2git --blobfile $PROJECT.blob --dumpfile $PROJECT.dump --username '(no author)' --fallback-encoding utf-8 $CVS/all

# Build a new Git repository from the extracted export
mkdir $GIT
cd $GIT
git init
cat ../$PROJECT.{blob,dump} | git fast-import
git gc --aggressive

# Clone to the original location we started in
cd $DEST
git clone --mirror $WORKSPACE/$GIT

# Clean up after ourselves
rm -rf $WORKSPACE

# Cancel the trap
trap - INT TERM EXIT

exit 0
{{< /codeblock >}}

Now simply upload your new repository to GitHub, or wherever else you feel is appropriate.

