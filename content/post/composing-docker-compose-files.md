---
title: DRY principle with docker-compose
date: 2018-08-09
categories:
  - devops
tags:
  - Docker
  - Spring-Boot-Primer
thumbnailImagePosition: left
thumbnailImage: /images/composing-thumbnail.jpg
---

An oft-repeated and sensible principle in software engineering is DRY, or
"don't repeat yourself". Here we will apply this principle to Docker compose
files.

<!--more-->

{{< alert info >}}
This post is part of the "Spring Boot Primer" [series](/tags/spring-boot-primer).
{{< /alert >}}

# Intended audience

This post assumes a basic level of familiarity with Docker compose files.
If you are not already familiar, there is good [documentation](https://docs.docker.com/compose/gettingstarted/)
available.

# Dependencies
To build the [source](https://github.com/pete-woods/spring-rest-example), you will
need JDK 8+, and a [Docker installation](https://docs.docker.com/install/).

# What are we aiming for?

Following the DRY principle, we would like to use Docker compose for both
development and production environments, with as little duplication as possible.

Docker compose will support this with its ability to compose, or layer, multiple
compose files together. In the application we are building, which is a simple
Spring Boot based REST API, we have the following service dependencies:

- Database (MariaDB)
- Cache (Redis)
- Administration console (Adminer)

## Development

In development we want to run the Spring Boot app normally, and have it be able to
connect to the database and cache inside the Docker network.

## Production

In production we want to run the entire stack inside Docker, we don't want to expose
the database or cache, but we **do** want to expose the Spring Boot App.

## Composing them together

This logically leads us to a set of three compose files, which will be pulled
together in two different combinations, as below:

{{< image
classes="fancybox nocaption center clear"
src="https://g.gravizo.com/svg? @startuml; [docker-compose.yml] as cf; [docker-compose-production.yml] as pf; [docker-compose-development.yml] as df; () \"Production\" as prod; prod -> cf ; prod --> pf ; () \"Development\" as dev; dev -> cf ; dev --> df ; @enduml;"
>}}

# Common services

The database, cache and admin tools will be common between both production and
development, so we create a shared `docker-compose.yml` as follows:

{{< codeblock "docker-compose.yml" "yml" "https://github.com/pete-woods/spring-rest-example/blob/master/docker-compose.yml" >}}
version: '3.3'

services:
  db:
    image: mariadb
    environment:
      MYSQL_DATABASE: 'backend'
      MYSQL_USER: 'backend'
    command:
      - '--character-set-server=utf8mb4'
      - '--collation-server=utf8mb4_unicode_ci'

  adminer:
    image: adminer
    ports:
      - '8081:8080'
    environment:
      ADMINER_DEFAULT_SERVER: db
    depends_on:
      - db

  cache:
    image: redis:alpine
    command: ["--notify-keyspace-events", "Egx"]
{{< /codeblock >}}

The object at line 4 defines our MariaDB service. We are asking for a database
and user to be created (lines 7 and 8), and asking for UTF8
support to be enabled by default (lines 10 and 11).

# Development

The development file needs to expose the ports for the database and cache so
that a locally run version of the application can access them. It also wires
a development-specific volume to the database service.

{{< codeblock "docker-compose-development.yml" "yml" "https://github.com/pete-woods/spring-rest-example/blob/master/docker-compose-development.yml" >}}
version: '3.3'

volumes:
  db-data-development:
    driver: local

services:
  db:
    volumes:
      - db-data-development:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: 'Uv6DFjqyBbGxGczOaQFCP8FnmOwP98FxNqxRezUZ5'
      MYSQL_PASSWORD: 'XfeCEtSOFL91QpeyDxQnkRattHWzufTdDB1Pn5iB4'
    ports:
      - '3306:3306'

  cache:
    ports:
      - '6379:6379'
{{< /codeblock >}}

## Running

To run up the development environment:

```
docker-compose -f docker-compose.yml -f docker-compose-development.yml up
```

Then start the Spring Boot application in your IDE, or with the command:
```
./mvnw spring-boot:run
```

# Production

The production file needs to start the Spring Boot application as a service,
and expose it outside of the Docker network. It also needs to connect a
volume to the database, that won't get mixed up with the development version.

We would also like to use different passwords for development and production.

{{< codeblock "docker-compose-production.yml" "yml" "https://github.com/pete-woods/spring-rest-example/blob/master/docker-compose-production.yml" >}}
version: '3.3'

volumes:
  backend-data:
    driver: local
  db-data-production:
    driver: local

services:
  db:
    volumes:
      - db-data-production:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: '3773Ir5oYOPuIwiJ3yylytG5kvRhOUYQafAVkTNBE'
      MYSQL_PASSWORD: 'WVn1X9JAZixu7bOCfITFSQyfru4wtRdqztf9PHE3s'

  cache:

  backend:
    image: surevine/spring-rest-example:latest
    volumes:
      - backend-data:/var/lib/data
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
    depends_on:
      - db
      - cache
{{< /codeblock >}}

## Running

To run up the production environment, we first need to build the image:

```
./mvnw package
```

Then we can run `docker-compose`:

```
docker-compose -f docker-compose.yml -f docker-compose-production.yml up
```
