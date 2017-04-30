---
title: C++ Glib/GObject wrappers
date: 2017-04-20
categories:
  - programming
tags:
  - C++
  - glib
  - gobject
thumbnailImagePosition: left
thumbnailImage: /img/potholes-thumbnail.jpg
---

One part of doing C++ the right way is using automatic variables for everything you possibly can. However at some point in your C++ endeavours, you’re likely to be using a C API of some sort, with explicit method calls to manage lifecycles, which can make this more difficult. My work at Canonical has involved talking to lots of these sorts of APIs, many of them based on GNOME’s [Glib](https://github.com/GNOME/glib). To make life easier, I have created a set of [easy to use wrappers](https://github.com/pete-woods/unity-api/tree/master/include/unity/util) to manage the lifecycle Glib and GObject objects.

<!--more-->

# Look out!

If you're used to modern languages that manage memory automatically, using these APIs can feel like an exercise in avoiding pitfalls. You will probably end up with multiple codepaths where you need to remember which set of resources to free.

<p></p>

{{< wide-image src="/img/potholes-wide.jpg" >}}

# Doing it the hard way

Below is an example of using the [GKeyFile](https://developer.gnome.org/glib/stable/glib-Key-value-file-parser.html) type in the traditional C-style way.

Although this is an intentionally trivial example, even here there are several places where it's possible to forget to free resources.

{{< codeblock "gkf-the-hard-way.cpp" "cpp" >}}

#include <glib.h>

using namespace std;

string get_string(const string& file) {
  auto gkf = g_key_file_new();
  g_key_file_load_from_file(gkf.get(), file.c_str(), G_KEY_FILE_NONE, nullptr);

  GError* error = nullptr;
  auto str = g_key_file_get_string(gkf, "group", "key", &error));

  if (error) {
    // remember to get the error message before freeing!
    invalid_argument e(error->message);
    g_key_file_unref(gkf); // don't forget!
    g_error_free(error); // don't forget!
    throw e;
  }

  // copy the gchar* into a temporary variable before freeing!
  string result(str);
  g_key_file_unref(gkf); // don't forget!
  g_free(str); // don't forget!

  // at this point str and gkf point to invalid memory.
  // remember not to access them!

  return result;
}
{{< /codeblock >}}

{{< alert danger >}}
Please note, the above code is an example of how **not** to do things.
{{< /alert >}}

# Smart pointers to the rescue!

Since C++11, we have access to the `std::shared_ptr` and `std::unique_ptr` smart pointer classes. These classes allow you to manage the lifecycle of heap variables (i.e. created using `new`) without needing to explicitly call `delete`.

Although by default these smart pointers call `delete` on the owned object when they go out of scope, they also allow you to specify a custom deleter. This means we can bind the correct 'undef' method from glib as the deleter, and forget about cleaning up ourselves.

In `<unity/util/GlibMemory.h>` the templated functions `unique_glib` and `share_glib` can be used to automatically construct a `std::unique_ptr` or `std::shared_ptr`, respectively, around the given Glib type.

For example `auto gkf = unique_glib(g_key_file_new());`. The `gkf` object is now wired up to call `g_key_file_unref()` when it is deleted. You can pass `gkf` to Glib APIs by accessing the underlying pointer, as follows: `g_key_file_load_from_file(gkf.get(), "/file/path.ini" , G_KEY_FILE_NONE, nullptr);`

# Error handling

Another common pain point in C APIs is error handling. Glib uses the `GError` type, passed by reference to store error information. This type itself must also be explicitly freed, in addition to any other resources.

```cpp
GError* error = nullptr;
auto str = g_key_file_get_string(gkf, "group", "key", &error));
if (error) {
  invalid_argument e(error->message);
  g_key_file_unref(gkf);
  g_error_free(error);
  throw e;
}
```

In `<unity/util/GlibMemory.h>` there is an assigner type, that allows Glib functions that take references to automatically have that type assigned to a smart pointer. An example of its usage is below:

```cpp
GErrorUPtr error;
auto str = unique_glib(g_key_file_get_string(gkf.get(), "group", "key",
                assign_glib(error)));
if (error) {
  throw invalid_argument(error->message);
}
```

Combining `unique_glib` and `assign_glib`, we can now freely throw an exception without the need to manually free all allocated resources. 

# Putting it together

Below is a simple example of putting all this together.

{{< codeblock "gkf-the-easier-way.cpp" "cpp" >}}
#include <unity/util/GlibMemory.h>

using namespace unity::util;
using namespace std;

string get_string(const string& file) {
  auto gkf = unique_glib(g_key_file_new());
  g_key_file_load_from_file(gkf.get(), file.c_str(), G_KEY_FILE_NONE, nullptr);

  GErrorUPtr error;
  auto str = unique_glib(g_key_file_get_string(gkf.get(), "group", "key",
        assign_glib(error)));

  if (error) {
    throw invalid_argument(error->message);
  }

  return string(str.get());
}
{{< /codeblock >}}

# What about GObjects and GIO?

Similarly to Glib, there are wrappers for GObject and GIO types in `<unity/util/GObjectMemory.h>`, which can be used in exactly the same way: 

{{< codeblock "gobjects.cpp" "cpp" >}}
auto o = unique_gobject(foo_bar_new_full("name"));

// Assign the name into a managed gchar*
gcharUPtr name;
g_object_get(G_OBJECT(o.get()), "name", assign_glib(name), nullptr);
{{< /codeblock >}}

Hope you found this post interesting!
