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
While Spring Boot [does import](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html) its
[common properties](https://docs.spring.io/spring-boot/docs/current/reference/html/common-application-properties.html) from environment variables,
sometimes you need to interpolate several variables together, e.g. to form a URL.

<!--more-->

{{< alert info >}}
This post is part of the "Spring Boot Primer" [series](/tags/spring-boot-primer).
{{< /alert >}}

Rather than littering your code with environment variables, simple variable interpolation in your `application.yml` or `application.properties`
can be used. You can also override the default values for built-in common properties this way:

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
    image: petewoods/spring-rest-example:latest
    deploy:
      replicas: 2
    volumes:
      - backend-data:/var/lib/data
    environment:
      DB_VENDOR: 'mariadb'
      DB_ADDR: 'db'
      DB_NAME: 'backend'
      DB_USER: 'backend'
      DB_PASSWORD: "${MYSQL_PASSWORD}"
      DB_DRIVER: 'org.mariadb.jdbc.Driver'
      SESSION_HOST: 'cache'
      SESSION_PASSWORD:
      SESSION_PORT: 6379
      MEDIA_LOCATION: 'file:/var/lib/data/'
      GOOGLE_CLIENT_ID: "${GOOGLE_CLIENT_ID}"
      GOOGLE_CLIENT_SECRET: "${GOOGLE_CLIENT_SECRET}"
      # AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      # AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      # CLOUDWATCH_METRICS_ENABLED: 'true'
      # CLOUDWATCH_METRICS_NAMESPACE: 'production-spring-rest-example'
      # MEDIA_LOCATION: 's3://my-bucket'
    ports:
      - '8080:8080'
{{< /codeblock >}}

then you can move your configuration in an environment file, and run as follows:

```
(. production.env && docker stack deploy --prune -c docker-compose.yml -c docker-compose-production.yml spring-rest-example)
```

or (even better) pull out into a secure key store such as [LastPass](https://www.lastpass.com/), and interpolate in
using something like LastPass CLI.
