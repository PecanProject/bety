---
layout: page
title: BETYdb development website
tagline: Developing the Biofuel Ecophysiological Traits and Yields Database web application
---
{% include JB/setup %}

This site links to source code for the Biofuel Ecophysiological Traits and Yields database (BETYdb) web application, which is located at [betydb.org](http://www.betydb.org)

The website is primarily written in Ruby-on-Rails, and has a MySQL backend. 
BETYdb provides an interface for contributing and accessing data, and is the informatics backend for the [Predictive Ecosystem Analyzer (PEcAn)](http://www.pecanproject.org).

See the [BETYdb wiki](https://github.com/pecanproject/bety/wiki] pages for documentation.

    
## Sample Posts

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>
