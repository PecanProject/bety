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

    
## Posts

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

<a class="twitter-timeline" href="https://twitter.com/BETYdatabase" data-widget-id="626768731251675136">Tweets by @BETYdatabase</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
