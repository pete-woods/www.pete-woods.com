---
title: Testing Qt-based DBus services
date: 2017-04-20
categories:
  - development
tags:
  - C++
  - Qt
  - DBus
  - testing
autoThumbnailImage: false
thumbnailImagePosition: "top"
thumbnailImage: /images/bus-thumbnail.jpg

---

DBus is the most common RPC middleware used in Linux desktop shell development. Unfortunately it does not provide much support for testing services using it. I created [libqtdbustest](https://github.com/pete-woods/libqtdbustest) and [libqtdbusmock](https://github.com/pete-woods/libqtdbusmock) to fill this gap, for Qt/C++ based services, at least.

<!--more-->

# A private bus

The first thing you need when testing DBus based services is your own private pair of DBus servers. When you instantiate the `QtDBusTest::DBusTestRunner` class, this is exactly what you get.

It has a zero argument constructor, so can easily be composed into your test fixture. It starts a new set of bus daemons, and terminates them on destrution.

```cpp
class TestMyStuff: public ::testing::Test {
protected:
  QtDBusTest::DBusTestRunner dbus_;
}
```

It provides methods to access the new instances of `QDBusConnection` for the private session and system buses: 

```cpp
TEST_F(TestMyStuff, DoesSomething) {
  dbus_.sessionConnection();
  dbus_.systemConnection();
}
```

# Starting services

You can register DBus services to be started and waited for. These services will be terminated when the test runner object is deleted.

```cpp
class TestMyStuff: public ::testing::Test {
protected:
  TestMyStuff() {
    dbus_.registerService(
        DBusServicePtr(new QProcessDBusService("org.freedesktop.MyBusName",
            QDBusConnection::SessionBus, "/path/to/executable/,
            QStringList{argument1, argument2})));

    dbus_.startServices();
  }

  QtDBusTest::DBusTestRunner dbus_;
}
```

# Mocking dependent services

The `QtDBusMock::DBusMock` class facilitates running mock DBus services for testing your interactions against. There are a number of built-in mocks for some common Linux services to use, or you can build your own from scratch.

```cpp
class TestMyStuff: public ::testing::Test {
protected:
  TestMyStuff() : mock_(dbus_) {
    mock_.registerLogin1({{"DefaultSeat", QVariantMap
    {
      {"CanMultiSession", canMultiSession},
      {"CanGraphical", canGraphical}
    }}});

    dbus_.registerService(
        DBusServicePtr(new QProcessDBusService("org.freedesktop.MyBusName",
            QDBusConnection::SessionBus, "/path/to/executable/,
            QStringList{argument1, argument2})));

    dbus_.startServices();
  }

  QtDBusTest::DBusTestRunner dbus_;
  QtDBusMock::DBusMock mock_;
}
```
