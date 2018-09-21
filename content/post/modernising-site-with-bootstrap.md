---
title: Modernising with Bootstrap, HTML5 and CSS3
date: 2017-11-02
categories:
  - development
tags:
  - bootstrap
  - css
  - html
thumbnailImagePosition: left
thumbnailImage: /images/boots-thumbnail.jpg
---

I was recently given the task of modernising a simple internal site's front-end. It was built using plain hand-written
HTML, CSS and JavaScript, with all layouts being done using HTML tables.

<!--more-->

I picked the latest version of Bootstrap for this, as there was also a desire to make the site function well
on mobile devices. Bootstrap is also very popular, well-supported with good documentation, and is
non-invasive in the sense that it can be combined with various toolsets such as plain server side
pages, or modern "single page" web applications.

# Background images

The first thing I did was hunt around the company's marketing assets to find some nice background imagery. I
wanted the image to work on both mobile and desktop, so I split it into three components: top, left and right.

The top part I always wanted centered at the top, so thinking "mobile-first", you can see the plain CSS below for
the body tag. However for larger screens I wanted to show the left and right components of the background
left and right aligned, respectively.

For this I used a very simple media query (line 5, below), aligning the other image components, combined with
a very handy CSS3 feature - [multiple backgrounds](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Backgrounds_and_Borders/Using_multiple_backgrounds).

{{< codeblock "login.css" "css" >}}
body {
  background: url('/images/bg-top-dark.svg') no-repeat fixed top center;
}

@media only screen and (min-width: 574px) {
  body {
    background:
      url('/images/bg-top-dark.svg') no-repeat fixed top center,
      url('/images/bg-left.svg') no-repeat fixed left 70%,
      url('/images/bg-right.svg') no-repeat fixed right 45%;
  }
}
{{< /codeblock >}}

You can see the complete login page below, making use of this background image.

{{< image classes="clear fancybox fig-100" src="/images/loc/login-new.png" thumbnail="/images/loc/login-new-thumbnail.png" title="New login screen">}}

The old front end used HTTP BASIC authentication, so there was no login screen. The new site
is based on Spring, using [Spring Security's](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#csrf) CSRF protection. Therefore we need to
include the CSRF as part of the login form. Normally this is done in your JSP using the Spring
Security CSRF tag:

{{< codeblock "Server side CSRF" "html" >}}
<form class="form-signin" action="<c:url value="/login"/>"
  method="post">
  <sec:csrfInput />
  ...
</form>
{{< /codeblock >}}

However this has the weakness that if the user spends a long peroiod of time waiting at the login
screen the CSRF token will expire. I use some simple JavaScript to fetch the CSRF token and insert
new hidden form elements dynamically when the user clicks "login".

{{< tabbed-codeblock "Client side CSRF" >}}
<!-- tab html -->
<form class="form-signin" action="<c:url value="/login"/>"
  method="post" onsubmit="return refreshCsrfAndSubmit(this);">
  ...
</form>
<!-- endtab -->
<!-- tab js -->
function apply(form, input, action) {
    var inputElement = form.elements.namedItem(input);
    if (inputElement !== null) {
        action.call(null, inputElement);
    }
}

function refreshCsrfAndSubmit(form) {
    if (form.elements.namedItem("_csrf") !== null
         && form.elements.namedItem("_csrf-timestamp") !== null
         && form.elements.namedItem("_csrf-timestamp").value >= (Date.now() - ${pageContext.session.maxInactiveInterval})) {
         return true;
     }

    var remove = function (input) {
        form.removeChild(input);
    };
    apply(form, "_csrf", remove);
    apply(form, "_csrf-timestamp", remove);

    var request = new XMLHttpRequest();
    request.ontimeout = function () {
        alert("Login failed: unable to obtain CSRF token");
        apply(form, "submit", function (button) {
            button.disabled = false;
        });
    };
    request.onload = function () {
        if (request.readyState === XMLHttpRequest.DONE && request.status === 200) {
            var csrfInput = document.createElement("input");
            csrfInput.type = "hidden";
            csrfInput.name = "_csrf";
            var json = JSON.parse(request.responseText);
            csrfInput.value = json.token;
            form.appendChild(csrfInput);

            var csrfTimestampInput = document.createElement("input");
            csrfTimestampInput.type = "hidden";
            csrfTimestampInput.name = "_csrf-timestamp";
            csrfTimestampInput.value = Date.now();
            form.appendChild(csrfTimestampInput);

            form.submit();
        }
    };
    request.onloadstart = function () {
        apply(form, "submitButton", function (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fa fa-refresh fa-spin"></i>';
        });
    };
    request.onloadend = function () {
        apply(form, "submitButton", function (button) {
            button.disabled = false;
            button.innerHTML = 'Sign in';
        });
    };

    request.open("GET", "<c:url value="/csrf"/>", true);
    request.timeout = 30000;
    request.send(null);

    return false;
}
<!-- endtab -->
{{< /codeblock >}}

# Home screen

The new look for the home screen basically fell out of simply deleting all the old CSS code, and
switching to Bootstrap-themed [tables](https://getbootstrap.com/docs/4.0/content/tables/).

{{< codeblock "table.html" "html" >}}
<table class="table table-striped table-sm table-bordered table-hover">
  <thead class="thead-dark">
    ...
  </thead>
  <tbody>
    ...
  </tbody>
</table>
{{< /codeblock >}}

{{< image classes="fancybox fig-50" src="/images/loc/home-old.png" thumbnail="/images/loc/home-old-thumbnail.png" title="Old home screen" >}}

{{< image classes="clear fancybox fig-50" src="/images/loc/home-new.png" thumbnail="/images/loc/home-new-thumbnail.png" title="New home screen" >}}


# Timesheet screen

The old timesheets screen didn't respond well to changes in viewport size. Some cells expanded beyound the boundary of
the table on small screens, for example. In addition to fixing the complex table-based layouts, I employed a few different
tricks to simplify and clean up the layout of this screen.

{{< image classes="fancybox fig-50" src="/images/loc/timesheets-old.png" thumbnail="/images/loc/timesheets-old-thumbnail.png" title="Old timesheet screen" >}}

{{< image classes="clear fancybox fig-50" src="/images/loc/timesheets-new.png" thumbnail="/images/loc/timesheets-new-thumbnail.png" title="New timesheet screen" >}}

* Move the timestamps into a tool-tip.
* Collapse the row of buttons for each row into a small Bootstrap drop-down button group.
* Hide infrequently-used parts of the UI (manual time sheet upload) behind a modal dialog.

{{< image classes="clear fancybox fig-100" src="/images/loc/upload-new.png" thumbnail="/images/loc/upload-new-thumbnail.png" title="Popup widget for infrequently-used manual upload">}}

# Responsive design

Bootstrap does most of the heavy lifting for making your site responsive, particularly with regards to its amazing
navbar control, which transforms completely. I also made use of Bootstrap's
[display](https://getbootstrap.com/docs/4.0/utilities/display/) classes to determine the
visibility of less important table columns, like so:

{{< codeblock "Responsive table" "html" >}}
<thead class="thead-inverse">
    <tr>
        <th class="text-center">Week</th>
        <th class="text-center d-none d-sm-table-cell">Time</th>
        <th class="text-center d-none d-md-table-cell">File Name</th>
        <th class="text-center">Status</th>
        <th class="text-center">Actions</th>
    </tr>
</thead>
{{< /codeblock >}}


See lines 4 and 5, where by default (on a mobile sized screen) the columns are not visible, but I bring them
visible again for certain breakpoints with the combination of e.g. `d-none d-sm-table-cell`. This results
in the following layouts.

{{< image classes="fancybox fig-33" src="/images/loc/login-responsive.png" thumbnail="/images/loc/login-responsive-thumbnail.png" title="Responsive login screen">}}

{{< image classes="fancybox fig-33" src="/images/loc/home-responsive.png" thumbnail="/images/loc/home-responsive-thumbnail.png" title="Responsive home screen">}}

{{< image classes="clear fancybox fig-33" src="/images/loc/timesheets-responsive.png" thumbnail="/images/loc/timesheets-responsive-thumbnail.png" title="Responsive timesheet screen">}}

# Search screen

The various serach screens in the app benefited from Bootstrap's
[form controls](https://getbootstrap.com/docs/4.0/components/forms/). The HTML to create
these search screens is quite simple, but the improvement is significant. Again, the screens
trivially become mobile-friendly because of Bootstrap.


{{< image classes="fancybox fig-50" src="/images/loc/query-old.png" thumbnail="/images/loc/query-old-thumbnail.png" title="Old search screen" >}}

{{< image classes="clear fancybox fig-50" src="/images/loc/query-new.png" thumbnail="/images/loc/query-new-thumbnail.png" title="New search screen" >}}

# Summary

I was able to completely overhaul this site's UI in a week, so I hope you can see from this that
modern HTML/CSS is really easy to get into, and produces pleasing results.

