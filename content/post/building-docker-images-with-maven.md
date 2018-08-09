---
title: Building Docker images with Maven
date: 2018-08-08
categories:
  - programming
tags:
  - Java
  - Maven
  - Docker
thumbnailImagePosition: left
thumbnailImage: /images/container-ship-thumbnail.jpg
---

To package our application, we're going to be using Docker. The natural
build language for Docker images are `Dockerfile`s, so we will use
[Spotify's Dockerfile Maven plugin](https://github.com/spotify/dockerfile-maven).

<!--more-->

To make packaging as simple as possible, we will bind the Maven plugin's
build phases to the default build phases, so that when you type
`./mvnw package`, your Docker image will be built.

# Dependencies
To build the [source](https://github.com/surevine/spring-rest-example), you will
need JDK 8+, and a [Docker installation](https://docs.docker.com/install/).

# Dockerfile

First create the [Dockerfile](https://github.com/surevine/spring-rest-example/blob/master/Dockerfile)
to construct our image, as below:

{{< codeblock "Dockerfile" >}}
FROM openjdk:jre-alpine
VOLUME /tmp
ARG JAR_FILE

ENV _JAVA_OPTIONS "-Xms256m -Xmx512m -Djava.awt.headless=true"

COPY ${JAR_FILE} /opt/app.jar

RUN addgroup bootapp && \
    adduser -D -S -h /var/cache/bootapp -s /sbin/nologin -G bootapp bootapp

WORKDIR /opt
USER bootapp
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/opt/app.jar"]
{{< /codeblock >}}

You can see that we are basing image on the official `openjdk:jre-alpine` image.
This will give us the latest Java JRE release based on the Alpine Linux
distribution.

We add an argument `ARG JAR_FILE` to parameterise the Docker image build. This will
allow Maven to provide us with the name of the JAR file to package.

We create a `/tmp` volume to speed up second launch times of the containers, as this
is where the embedded application container stores its exploded contents to.

We set up an environment variable `ENV _JAVA_OPTIONS` to configure the JVM to
some sensible values for hosting a web service. The default values here can easily
be overridded when composing this image later.

We add a user and group for the image, so that the application does not run as root.

Lastly we tell Java to use `/dev/urandom` for its random number seed to improve boot
times.

# Maven POM file

Now we need to add a pair of properties to configure the image builder:

{{< codeblock "pom.xml" "xml" >}}
<properties>
  ...
  <dockerfile.version>1.4.1</dockerfile.version>
  <docker.image.prefix>surevine</docker.image.prefix>
  ...
</properties>
{{< /codeblock >}}

In the `plugins` section, we also need to add the actual Dockerfile Maven plugin.
There are only two interesting parts to this:

1. The `executions` section, to wire up the Dockerfile build bases to the default ones.
2. The `dependencies` section, which makes this plugin work against later versions of 
   the JDK.

{{< codeblock "pom.xml" "xml" >}}
<plugins>
  ...
  <plugin>
    <groupId>com.spotify</groupId>
    <artifactId>dockerfile-maven-plugin</artifactId>
    <version>${dockerfile.version}</version>
    <!-- Wire up to the default build phases -->
    <executions>
      <execution>
        <id>default</id>
        <goals>
          <goal>build</goal>
          <goal>push</goal>
        </goals>
      </execution>
    </executions>
    <configuration>
      <repository>${docker.image.prefix}/${project.artifactId}</repository>
      <buildArgs>
        <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
      </buildArgs>
    </configuration>
    <dependencies>
      <!-- To make this work on JDK 9+ -->
      <dependency>
        <groupId>javax.activation</groupId>
        <artifactId>javax.activation-api</artifactId>
        <version>1.2.0</version>
      </dependency>
    </dependencies>
  </plugin>
  ...
</plugins>
{{< /codeblock >}}

# Building

Once this is complete, the Docker image can be built simply by running:
```
./mvnw package
```
