transmission-rss
================

transmission-rss is basically a workaround for transmission's lack of the
ability to monitor RSS feeds and automatically add enclosed torrent links.

It works with transmission-daemon and transmission-gtk (if the web frontend
is enabled in the settings dialog). Sites like showrss.karmorra.info and
ezrss.it or self-hosted seriesly instances are suited well as feed sources.

A tool called transmission-add-file is also included for mass adding of
torrent files.

As it's done with poems, I devote this very artful and romantic piece of
code to the single most delightful human being: Ann.

Installation
------------

### Latest stable version from rubygems.org

    gem install transmission-rss

### From source

    git clone git://git.orgizm.net/transmission-rss.git
    cd transmission-rss
    gem build transmission-rss.gemspec
    gem install transmission-rss-*.gem

Configuration
-------------

A yaml formatted config file is expected at `/etc/transmission-rss.conf`.

### Minimal example

It should at least contain a list of feeds:

    feeds:
      - http://example.com/feed1
      - http://example.com/feed2

Feed item titles can be filtered by a regular expression:

    feeds:
      - http://example.com/feed1:
        regexp: foo
      - http://example.com/feed2:
        regexp: (foo|bar)

### All available options

The following configuration file example contains every existing option
(although `update_interval`, `add_paused` and `server` are default values
and could be omitted). The default `log_target` is STDERR. `privileges` is
not defined by default, so the script runs as current user/group.

    feeds:
      - http://example.com/feed1
      - http://example.com/feed2
      - http://example.com/feed3:
        regexp: match1
      - http://example.com/feed4:
        regexp: (match1|match2)

    update_interval: 600

    add_paused: false

    server:
      host: localhost
      port: 9091

    log_target: /var/log/transmissiond-rss.log

    privileges:
      user: nobody
      group: nobody

    fork: false

    pid_file: false

TODO
----

* Option to stop seeding after full download.
* Configurable log level.
