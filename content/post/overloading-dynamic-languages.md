---
title: No overloading in dynamically typed languages makes sense
date: 2012-05-03
categories:
  - programming
tags:
  - Ruby
thumbnailImagePosition: left
thumbnailImage: /images/overloaded-thumbnail.jpg
---

Over the last few years I have become a much bigger fan of dynamic languages like Ruby and Python. Today I was thinking about one of my old gripes about dynamic languages, which was a lack of method overloading.

<!--more-->

Thinking about this at lunchtime, I realised how a lack of overloading strong encourages the developer to use the principle of inversion.

From a Java-centric world, imagine a very simple and contrived case, such as below:

```java
void draw(Square square) {
  draw(square, Color.BLACK);
}

void draw(Square square, Color color) {
  gc.setColor(color);
  gc.point(square.topLeft());
  gc.point(square.topRight());
  gc.point(square.bottomLeft());
  gc.point(square.bottomRight());
}
```

The idea is that you may optionally give a colour to the draw method. In Ruby (to begin with) I was doing things like this:

```ruby
def draw_square(square)
  draw_square_with_color(square, Color.BLACK)
end

def draw_square_with_color(square, color)
  gc.set_color(color)
  gc.point(square.top_left)
  gc.point(square.top_right)
  gc.point(square.bottom_left)
  gc.point(square.bottom_right)
end
```

which of course is wrong, simply because I hadn't heard of option arguments. Clearly you don't need (or want) to overload in this situation. It should read more like this:

```ruby
def draw(square, color = Color.BLACK)
gc.set_color(color)
square.corners.each {|point| gc.point(point)}
end
```

Because I'm trying not to encode type information I don't do this in a dynamic language, and so I'm forced to think about the "duck" interface of the things I'm drawing with from the beginning.

As soon as I start adding more types of thing to draw, my class gains methods rapidly:

```java
void draw(Square square) {
draw(square, Color.BLACK);
}

void draw(Square square, Color color) {
  gc.setColor(color);
  gc.point(square.topLeft());
  gc.point(square.topRight());
  gc.point(square.bottomLeft());
  gc.point(square.bottomRight());
}

void draw(Triangle triangle, Coordinate bottomRight) {
  draw(triangle, Color.BLACK);
}

void draw(Triangle triangle, Color color) {
  gc.setColor(color);
  gc.point(top);
  gc.point(bottomLeft);
  gc.point(bottomRight);
}
```

Now, of course, the answer to this is to find some kind of common interface for the things you are drawing. I find you have to be really disciplined to avoid going down this route in static languages. Interfaces (especially in C++) can be a pain to extract.

Because I already figured out the duck typing for the square, I simply treat a shape like a square:

```ruby
def draw(shape, color = Color.BLACK)
  gc.set_color(color)
  shape.corners.each {|point| gc.point(point)}
end
```

I find this type of thing just naturally happens when I program in Ruby and Python, in contrast to C++ or Java.

