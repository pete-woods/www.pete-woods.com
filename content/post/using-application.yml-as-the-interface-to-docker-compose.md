---
title: Using application.yml as the interface to Docker
date: 2018-09-17
categories:
  - development
tags:
  - Docker
  - Java
  - Spring
  - Spring-Boot-Primer
thumbnailImagePosition: left
thumbnailImage: /images/jigsaw-thumbnail.jpg
---

Modern containerised [12 factor](https://12factor.net/) applications are expected to derive their configuration from environment variables.
While Spring Boot [does import](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html) some of
its properties from environment variables, it doesn't for most of its
[common properties](https://docs.spring.io/spring-boot/docs/current/reference/html/common-application-properties.html).

<!--more-->

{{< alert info >}}
This post is part of the "Spring Boot Primer" [series](/tags/spring-boot-primer).
{{< /alert >}}

To avoid littering your code with environment variable names, and allow you to configure the common Spring Boot properties it's simply a matter of using variable interpolation in your `application.yml` or `application.properties`.

Hello!

{{< codeblock "application.yml" "yml" "https://github.com/pete-woods/spring-rest-example/blob/master/src/main/resources/application.yml" >}}
spring:

  datasource:
    url: jdbc:${DB_VENDOR:mariadb}://${DB_ADDR:localhost}:${DB_PORT:3306}/${DB_NAME:backend}
    username: ${DB_USER:backend}
    password: ${DB_PASSWORD:XfeCEtSOFL91QpeyDxQnkRattHWzufTdDB1Pn5iB4}
    driver-class-name: ${DB_DRIVER:org.mariadb.jdbc.Driver}

  session:
    store-type: ${SESSION_STORE_TYPE:redis}

  redis:
    host: ${SESSION_HOST:localhost}
    password: ${SESSION_PASSWORD:}
    port: ${SESSION_PORT:6379}
{{< /codeblock >}}

To allow you to set sensible defaults, so that your application can be started straight from your IDE with no additional
configuration, you can also embed your development environment defaults, with the normal BASH-style syntax:
```
${DB_PASSWORD:XfeCEtSOFL91QpeyDxQnkRattHWzufTdDB1Pn5iB4}
```

At development-time (either running the app locally in your IDE / CLI or in Docker), you don't need to provide any additional
configuration; making set-up for new developers on your team very rapid.

At production-time, all of these properties can easily be set via your `docker-compose.yml`:
{{< codeblock "docker-compose-production.yml" "yml" "https://github.com/pete-woods/spring-rest-example/blob/master/docker-compose-production.yml" >}}
services:
  backend:
    image: surevine/spring-rest-example:latest
    environment:
      DB_VENDOR: 'mariadb'
      DB_ADDR: 'db'
      DB_NAME: 'backend'
      DB_USER: 'backend'
      DB_PASSWORD: 'WVn1X9JAZixu7bOCfITFSQyfru4wtRdqztf9PHE3s'
      DB_DRIVER: 'org.mariadb.jdbc.Driver'
      SESSION_HOST: 'cache'
      SESSION_PASSWORD:
      SESSION_PORT: 6379
      MEDIA_LOCATION: 'file:/var/lib/data/'
    ports:
      - '8080:8080'
{{< /codeblock >}}

or (even better) pull out into a secure key store such as [LastPass](https://www.lastpass.com/).
