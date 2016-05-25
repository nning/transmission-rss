transmission-rss
================

[![Gem Version](https://img.shields.io/gem/v/transmission-rss.svg)](http://badge.fury.io/rb/transmission-rss)
[![Build Status](https://img.shields.io/travis/nning/transmission-rss/master.svg)](https://travis-ci.org/nning/transmission-rss)
[![Coverage Status](https://img.shields.io/coveralls/nning/transmission-rss/master.svg)](https://coveralls.io/r/nning/transmission-rss)
[![Code Climate](https://img.shields.io/codeclimate/github/nning/transmission-rss.svg)](https://codeclimate.com/github/nning/transmission-rss)

transmission-rss is basically a workaround for transmission's lack of the
ability to monitor RSS feeds and automatically add enclosed torrent links.

It works with transmission-daemon and transmission-gtk (if the web frontend
is enabled in the settings dialog). Sites like showrss.karmorra.info and
ezrss.it or self-hosted seriesly instances are suited well as feed sources.

A tool called transmission-add-file is also included for mass adding of
torrent files.

As it's done with poems, I devote this very artful and romantic piece of
code to the single most delightful human being: Ann.

The minimum supported Ruby version is 1.9.3.

Installation
------------

### Latest stable version from rubygems.org

    gem install transmission-rss

### From source

    git clone https://github.com/nning/transmission-rss
    cd transmission-rss
	bundle
    gem build transmission-rss.gemspec
    gem install transmission-rss-*.gem

Configuration
-------------

A yaml formatted config file is expected at `/etc/transmission-rss.conf`. Users
can override some options for their transmission-rss instances by providing a
config at `~/.config/transmission-rss/config.yml` (or in `$XDG_CONFIG_HOME`
instead of `~/.config`).

### Minimal example

It should at least contain a list of feeds:

    feeds:
      - url: http://example.com/feed1
      - url: http://example.com/feed2

Feed item titles can be filtered by a regular expression:

    feeds:
      - url: http://example.com/feed1
        regexp: foo
      - url: http://example.com/feed2
        regexp: (foo|bar)

Feeds can also be configured to download files to specific directory:

    feeds:
      - url: http://example.com/feed1
        download_path: /home/user/Downloads

### All available options

The following configuration file example contains every existing option
(although `update_interval`, `add_paused`, `server`, `fork`, and `pid_file` are
default values and could be omitted). The default `log_target` is STDERR.
`privileges` is not defined by default, so the script runs as current
user/group. `login` is also not defined by default. It has to be defined, if
transmission is configured for HTTP basic authentication.

    feeds:
      - url: http://example.com/feed1
      - url: http://example.com/feed2
      - url: http://example.com/feed3
        regexp: match1
      - url: http://example.com/feed4
        regexp: (match1|match2)
      - url: http://example.com/feed4
        download_path: /home/user/Downloads
      - url: http://example.com/feed4
        regexp:
          - match1
          - match2
      - url: http://example.com/feed5
        regexp:
          - matcher: match1
		  	download_path: /home/user/match1
          - matcher: match2
		  	download_path: /home/user/match2

    update_interval: 600

    add_paused: false

    server:
      host: localhost
      port: 9091
      rpc_path: /transmission/rpc

	login:
	  username: transmission
	  password: transmission

    log_target: /var/log/transmissiond-rss.log

    privileges:
      user: nobody
      group: nobody

    fork: false

    pid_file: false

Daemonized Startup
------------------

The following content can be saved into
`/etc/systemd/system/transmission-rss.service` to create a systemd unit.
Remember checking the path in `ExecStart`.

    [Unit]
    Description=Transmission RSS daemon.
    After=network.target transmission-daemon.service

    [Service]
    Type=forking
    ExecStart=/usr/local/bin/transmission-rss -f
    ExecReload=/bin/kill -s HUP $MAINPID

    [Install]
    WantedBy=multi-user.target

The unit files are reloaded by `systemctl daemon-reload`. You can then start
transmission-rss by running `systemctl start transmission-rss`. Starting on
boot, can be enabled `systemctl enable transmission-rss`.
