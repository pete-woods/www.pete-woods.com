---
title: PDE build gotcha when upgrading from Eclipse 3.4 to 3.5
date: 2010-09-24
categories:
  - programming
tags:
  - Java
  - Eclipse
thumbnailImagePosition: left
thumbnailImage: /images/crash-thumbnail.jpg
---

If you're currently executing your target platform that you build your product from instead of a properly installed Eclipse, you will have troubles when you upgrade. Eclipse 3.5 and above don't count plug-ins as installed by simply unzipping - the configuration meta data must refer to them. The best way is to download a complete Eclipse and unzip this somewhere on your build server, instead of assembling it from components at build time. Guess we should have been doing this all along.

<!--more-->

If you don't do this you'll get an error something like this:

```
Property "eclipse.pdebuild.templates" has not been set
```

which isn't very helpful.

This is because the Eclipse AntRunner application sets up all kinds of special ant properties and tasks based upon an extension point, and if Eclipse doesn't find the right plug-ins (which it won't if it doesn't think they are installed) you won't get them!

