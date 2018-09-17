---
title: Spring as a Java container abstraction - switching to Undertow
date: 2018-08-13
categories:
  - development
tags:
  - Java
  - Spring
  - Spring-Boot-Primer
thumbnailImagePosition: left
thumbnailImage: /images/undertow-thumbnail.jpg
---

Spring MVC abstracts the Java servlet container implementation away from you
almost completely, this allows you to migrate from Tomcat quite easily.

<!--more-->

{{< alert info >}}
This post is part of the "Spring Boot Primer" [series](/tags/spring-boot-primer).
{{< /alert >}}

Unless you have somehow tied yourself into Tomcat, perhaps by customising its
configuration, or directly taking advantage of some Tomcat-specific feature,
then all that is required is taking the default `spring-boot-starter-web`
dependency:

{{< codeblock "pom.xml" >}}
<dependencies>
  ...
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  ...
</dependencies>
{{< /codeblock >}}

and then replacing it with the following:

{{< codeblock "pom.xml" "xml" "https://github.com/pete-woods/spring-rest-example/blob/master/pom.xml" >}}
<dependencies>
  ...
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
      <exclusion>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-tomcat</artifactId>
      </exclusion>
    </exclusions>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-undertow</artifactId>
  </dependency>
  ...
</dependencies>
{{< /codeblock >}}

All this does is exclude Tomcat from the web starter, and lets you add
either Undertow or Jetty as an alternative Java web container.
