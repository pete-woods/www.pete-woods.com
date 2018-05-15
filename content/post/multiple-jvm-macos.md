---
title: Multiple JVM versions on macOS
date: 2018-01-13
categories:
  - development
tags:
  - Java
  - JVM
  - Brew
  - Jenv
  - OSX
  - macOS
thumbnailImagePosition: left
thumbnailImage: /images/coffee-thumbnail.jpg
---

It's pretty common when doing Java development to need mutiple versions installed alongside each other.
With Brew and Jenv, switching Java versions between projects becomes easy.

<!--more-->


# Set up the versions cask

First you need to tap the `versions` cask:

~~~ sh
$ brew tap caskroom/versions
~~~

Now you can see multiple versions of the Java cask:

~~~ sh
$ brew cask search java
==> Exact Match
java ✔
==> Partial Matches
charles-applejava                           eclipse-java
java-jdk-javadoc                            java6
java8                                       netbeans-java-ee
netbeans-java-se                            yourkit-java-profiler
~~~

# Install desired Java versions

Now we have the `versions` cask, we can install our desired version of Java, e.g.:

~~~ sh
$ brew cask install java8
~~~

At this point, you can not easily switch between the different Java versions, and the most recent Java version will be used.

# Install and set up Jenv

Jenv allows you to manage the environment for multiple Java installs, and works well with Brew's managed versions of Java.

~~~ sh
$ brew install jenv
~~~

To enable the Jenv shims and autocompletion:

~~~ sh
$ echo 'if which jenv > /dev/null; then eval "$(jenv init -)"; fi' >> ~/.bash_profile
~~~

Now restart your shell by either re-opening Terminal, or running the following:

~~~ sh
$ exec $SHELL -l
~~~

# Add JVMs to Jenv

Add your JVMs to Jenv as follows:

~~~  sh
$ jenv add /Library/Java/JavaVirtualMachines/jdk-9.0.4.jdk/Contents/Home/
$ jenv add /Library/Java/JavaVirtualMachines/jdk1.8.0_162.jdk/Contents/Home/
~~~

By default, Jenv will be using the system installed version of Java, which will be the latest one.

You can override this globally by running:

~~~  sh
$ jenv global oracle64-1.8.0.162
~~~

or if you just want to affect a particular project:

~~~ sh
$ jenv local oracle64-1.8.0.162
~~~

# Check it works

~~~  sh
$ java -version
~~~

# Enable Maven shim

If you're using Maven on the CLI, you will want to enable the Maven shim, otherwise it will still be using the system version of Java:

~~~ sh
$ jenv enable-plugin maven
~~~

# Command Reference

See the [Jenv site](http://www.jenv.be/) for more details.
