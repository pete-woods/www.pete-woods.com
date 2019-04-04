
---
title: Production-grade Spring Boot Docker images
date: 2019-02-14
categories:
  - development
tags:
  - Docker
  - Java
  - Spring
  - Spring-Boot-Primer
thumbnailImagePosition: left
thumbnailImage: /images/bricks-thumbnail.jpg
---

There are plenty examples of basic Dockerfile based builds out there, but a production
application requires a bunch of different things, such as reproducibility, hardening,
health checks, static analysis - and ideally still be quick to build.

<!--more-->

# Multi-stage Docker builds

Being able to build you software in exactly the same way as your CI system is highly
desirable. No-one wants their dev cycle to involve CI, no-matter how quick it is.
Multi-stage Docker builds are a great way to achieve this.

Below is an outline of how to structure a multi-stage build.

{{< codeblock "Naive Dockerfile" "" "" >}}
# Build-time image that is discarded
FROM openjdk:11-jdk-slim AS java-build
COPY . .
RUN ./mvnw package

# Run-time image that makes the final image
FROM openjdk:11-jre-slim
COPY --from=java-build /app/app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
{{< /codeblock >}}

The key things to note are:

1. The `java-build` image, and any other images except the last `FROM`, will
   be discarded at the end of the build, and used again only for layer caching.
2. In the second image, we only `COPY` build artefacts from the `java-build`
   image, as we have no compilation tools, (and later on not even a shell).

{{< alert warning >}}
At the moment, unfortunately, this `Dockerfile` is still quite naive, and a full
download of all our dependencies will occur each time we run the build.
{{< /alert >}}

# Caching dependencies

If we want the build to be fast (we do), then we can start to take advantage
of Docker's layer caching to speed it up. Docker builds use caches for each
build step until it sees a layer change. In our case, our dependencies only
change when someone either updates the Maven wrapper, or the pom file.

So if we only copy those files, and then have a `RUN` step that only downloads
the dependencies (`./mvnw dependency:go-offline`), we can cache them in a
separate layer, and only re-compute them when needed. See below:

{{< codeblock "Dependency caching" "" "" >}}
WORKDIR /app/

# Copy the files that affect dependencies (Maven pom and wrapper)
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
# Download our dependencies into this layer
RUN ./mvnw dependency:go-offline

# Now copy the source (which doesn't affect the dependencies)
COPY src src
# Now build
RUN ./mvnw package

# Build the runtime image...
{{< /codeblock >}}

{{< alert info >}}
We only `COPY` the actual Java `src` dir after the dependencies are downloaded.
{{< /alert >}}


# Reducing partial image sizes

We've successfully improve the build times for our image. The next thing to optimise is the
amount that needs re-downloading each time our application is updated. Right now, we're using
Spring Boot's default [uber JAR](https://docs.spring.io/spring-boot/docs/current/reference/html/getting-started-first-application.html#getting-started-first-application-executable-jar)
packaging, which with a decent sized application, can easily start reaching in the order of
50+ MiB.

We don't want to download 50 MiB of double-packed JARs each time a trivial change is made to
the application, so in our Docker builds we should carefully unpack this JAR, putting the
dependencies in a separate layer than our compiled code.

{{< codeblock "Smaller downloads" "" "" >}}
FROM openjdk:11-jdk-slim AS java-build

WORKDIR /app/

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline

COPY src src
RUN ./mvnw package
# Un-pack the uber-JAR
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)


FROM openjdk:11-jre-slim

# There are no variables in Dockerfiles, so we use an ARG
ARG DEPENDENCY=/app/target/dependency
# First our dependencies
COPY --from=java-build ${DEPENDENCY}/BOOT-INF/lib /app/lib
# Then the application metadata
COPY --from=java-build ${DEPENDENCY}/META-INF /app/META-INF
# Finally our application's classes
COPY --from=java-build ${DEPENDENCY}/BOOT-INF/classes /app

# We now run Java with a classpath definition, instead of a link to a JAR
ENTRYPOINT ["java","-cp","app:app/lib/*","com.surevine.springrestexample.Application"]
{{< /codeblock >}}

{{< alert info >}}
We order the layers in least order of "likeliness to change", so our dependencies go
first, and our own classes last.
{{< /alert >}}

{{< alert warning >}}
Remember to change the last time to your own main class.
{{< /alert >}}

# Static analysis

Always recommended is static analysis of your code, so let's enable SonarQube in
our builds. The Spring Boot start parent already includes Sonar in its plugin
dependencies, so all we need to do is invoke the right Maven goal with the right
configuration.

We don't want to store sensitive data in the Dockerfile or version control, so let's only run
Sonar when we give it some credentials, taking the arguments `SONAR_HOST_URL` and
`SONAR_AUTH_TOKEN`.

{{< codeblock "Static analysis" "" "" >}}
FROM openjdk:11-jdk-slim AS java-build
# ...
RUN ./mvnw package
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

ARG SONAR_HOST_URL
ARG SONAR_AUTH_TOKEN
RUN set -e; \
    if [ "${SONAR_HOST_URL}" != "" ]; then \
        ./mvnw sonar:sonar -Dsonar.host.url="${SONAR_HOST_URL}" -Dsonar.auth.token=${SONAR_AUTH_TOKEN}; \
    fi
# ...
{{< /codeblock >}}

{{< alert warning >}}
The `SONAR_HOST_URL` and `SONAR_AUTH_TOKEN` parameters should be stored securely
inside your CI system's key store, and not in your build script.
{{< /alert >}}


# Hardening your container

## Minimise attack surface

To reduce the attack surface of our final image we should avoid copying any un-necessary
executable files, such as C/C++ libraries, shells, etc. Google's
[Distroless](https://github.com/GoogleContainerTools/distroless) base images seek to
achieve exactly this; providing a Java image that only includes the bare essentials
to make it function (JRE, ca-certificates, tzdata, glibc, libssl).

It's pretty straightforward to take advantage of this in a Java application, by simply
changing the base image, and making sure your entrypoint is using the JSON form
`ENTRYPOINT ["/app/myapp"]`, as we have no shell.


{{< codeblock "Dockerfile" "" "https://github.com/pete-woods/spring-rest-example/blob/master/Dockerfile" >}}
FROM openjdk:11-jdk-slim AS java-build
# ...
FROM gcr.io/distroless/java:11
# ...
{{< /codeblock >}}


{{< alert warning >}}
Don't use the shell form for `ENTRYPOINT` - it won't work.
{{< /alert >}}

## Non-root user

It's important to run your application as a non-root user, so it can't break out of its
container as easily, if compromised. This is normally done by adding a user to the
image with `RUN adduser username ...` to add the user, and then a `USER username` build
step to make the container run as that user by default.

However, because the final image is based on `gcr.io/distroless/java`, we can't simply
`RUN` a shell command, so we must do it in the build image, then copy the `/etc/passwd`
and `/etc/shadow` files over to the final image.

{{< codeblock "Non-root user" "" "" >}}
FROM openjdk:11-jdk-slim AS java-build
# ...
RUN adduser --system --home /var/cache/bootapp --shell /sbin/nologin bootapp;
# ...
FROM gcr.io/distroless/java:11
COPY --from=java-build /etc/passwd /etc/shadow /etc/
USER bootapp
# ...
{{< /codeblock >}}

# Health-checks without BASH or curl

Health-checks essentially doing `curl http://localhost:8080` are quite common practise
in Docker. However, we're trying to avoid having a shell, or other general purpose
utilities like `curl` and `libcurl`. The best solution I have found is a simple GoLang
tool that has the URL hard-coded.

{{< codeblock "healthcheck.go" "go" "https://github.com/pete-woods/spring-rest-example/blob/master/cmd/healthcheck/main.go" >}}
package main

import (
	"net/http"
	"os"
)

func main() {
	_, err := http.Get("http://127.0.0.1:8080/actuator/info")
	if err != nil {
		os.Exit(1)
	}
}
{{< /codeblock >}}

This tool can be built in a separate stage, using the official GoLang image, then
copied into your final image, in the same way as the main application. Lastly,
reference the healthcheck in a `HEALTHCHECK` step, again remembering to use the
JSON form.

{{< codeblock "Dockerfile" "" "https://github.com/pete-woods/spring-rest-example/blob/master/Dockerfile" >}}
FROM openjdk:11-jdk-slim AS java-build
# ...

FROM golang:1.12 as golang-build
WORKDIR /go/src/app
COPY cmd cmd
RUN go install -v ./...

FROM gcr.io/distroless/java:11
COPY --from=golang-build /go/bin/healthcheck /app/healthcheck
HEALTHCHECK --start-period=120s CMD ["/app/healthcheck"]
# ...
{{< /codeblock >}}

{{< alert warning >}}
Remember to use the JSON form: `HEALTHCHECK CMD ["/app/healthcheck"]`
{{< /alert >}}


# JVM container memory stuffs for Java 11+

Since Java 11, the JRE has support for knowing about the container resource limits
without any special extra configuration. This means we can simply set the flag
`-XX:MaxRAMPercentage=90`, and not need to do any complex calculations about the
other memory our application will use besides the heap.

{{< codeblock "Memory settings" "" "" >}}
ENV _JAVA_OPTIONS "-XX:MaxRAMPercentage=90 -Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Dfile.encoding=UTF-8"
{{< /codeblock >}}

# The final result

Below is the final `Dockerfile`, which can be found [here](https://github.com/pete-woods/spring-rest-example/blob/master/Dockerfile)
in the [example repository](https://github.com/pete-woods/spring-rest-example).

{{< codeblock "Dockerfile" "" "https://github.com/pete-woods/spring-rest-example/blob/master/Dockerfile" >}}
FROM openjdk:11-jdk-slim AS java-build

WORKDIR /app/

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline

COPY src src
RUN ./mvnw package
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

ARG SONAR_HOST_URL
ARG SONAR_AUTH_TOKEN
RUN set -e; \
    if [ "${SONAR_HOST_URL}" != "" ]; then \
        ./mvnw sonar:sonar -Dsonar.host.url="${SONAR_HOST_URL}" -Dsonar.auth.token=${SONAR_AUTH_TOKEN}; \
    fi

RUN adduser --system --home /var/cache/bootapp --shell /sbin/nologin bootapp;




FROM golang:1.12 as golang-build

WORKDIR /go/src/app
COPY cmd cmd

RUN go install -v ./...




FROM gcr.io/distroless/java:11

COPY --from=golang-build /go/bin/healthcheck /app/healthcheck
HEALTHCHECK --start-period=120s CMD ["/app/healthcheck"]

COPY --from=java-build /etc/passwd /etc/shadow /etc/
ARG DEPENDENCY=/app/target/dependency
COPY --from=java-build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=java-build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=java-build ${DEPENDENCY}/BOOT-INF/classes /app

USER bootapp
ENV _JAVA_OPTIONS "-XX:MaxRAMPercentage=90 -Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Dfile.encoding=UTF-8"
ENTRYPOINT ["java","-cp","app:app/lib/*","com.surevine.springrestexample.Application"]
{{< /codeblock >}}


