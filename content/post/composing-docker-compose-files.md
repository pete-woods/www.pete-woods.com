---
title: DRY principle with docker-compose
date: 2018-08-09
categories:
  - programming
tags:
  - Docker
  - DevOps
thumbnailImagePosition: left
thumbnailImage: /images/composing-thumbnail.jpg
---

An oft-repeated and sensible principle in software engineering is DRY, or
"don't repeat yourself". Here we will apply this principle to Docker compose
files.

<!--more-->

# Intended audience

This post assumes a basic level of familiarity with Docker compose files.
If you are not already familiar, there is good [documentation](https://docs.docker.com/compose/gettingstarted/)
available.

# Dependencies
To build the [source](https://github.com/surevine/spring-rest-example), you will
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

{{< codeblock "docker-compose.yml" "yml" "https://github.com/surevine/spring-rest-example/blob/master/docker-compose.yml" >}}
version: '3.3'

volumes:
  db-data:
    driver: local

services:
  db:
    image: mariadb
    volumes:
      - db-data:/var/lib/mysql
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

The object at line 8 defines our MariaDB service. We are wiring up a volume (line 10),
asking for a database and user to be created (lines 13 and 14), and asking for UTF8
support to be enabled by default (lines 16 and 17).

# Development

{{< codeblock "docker-compose-development.yml" "yml" "https://github.com/surevine/spring-rest-example/blob/master/docker-compose-development.yml" >}}
{{< /codeblock >}}

# Production

{{< codeblock "docker-compose-production.yml" "yml" "https://github.com/surevine/spring-rest-example/blob/master/docker-compose-production.yml" >}}
{{< /codeblock >}}