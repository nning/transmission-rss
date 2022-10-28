transmission-rss
================

[![Gem Version](https://img.shields.io/gem/v/transmission-rss.svg)](http://badge.fury.io/rb/transmission-rss)
[![Build Status](https://img.shields.io/travis/nning/transmission-rss/master.svg)](https://travis-ci.org/nning/transmission-rss)
[![Coverage Status](https://img.shields.io/coveralls/nning/transmission-rss/master.svg)](https://coveralls.io/r/nning/transmission-rss)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/nning/transmission-rss.svg)](https://codeclimate.com/github/nning/transmission-rss)
[![Docker Hub Build Status](https://img.shields.io/docker/build/nning2/transmission-rss.svg)](https://hub.docker.com/r/nning2/transmission-rss/)

transmission-rss is basically a workaround for transmission's lack of the
ability to monitor RSS feeds and automatically add enclosed torrent links.

It works with transmission-daemon and transmission-gtk (if the web frontend
is enabled in the settings dialog). Sites like showrss.karmorra.info and
ezrss.it or self-hosted seriesly instances are suited well as feed sources.

A tool called transmission-add-file is also included for mass adding of
torrent files.

As it's done with poems, I devote this very artful and romantic piece of
code to the single most delightful human being: Ann.

The minimum supported Ruby version is 2.1. (You will need `rbenv` if your
os does not support Ruby >= 2.1, e.g. on Debian wheezy.)

**Note, that this README is for the current development branch!** You can find
a link to a suitable README for your version
[on the releases page](https://github.com/nning/transmission-rss/releases).

Installation
------------

### Latest stable version from rubygems.org

```sh
gem install transmission-rss
```

### From source

```sh
git clone https://github.com/nning/transmission-rss
cd transmission-rss
bundle
gem build transmission-rss.gemspec
gem install transmission-rss-*.gem
```

### Via Docker

```sh
docker run -t \
  -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf \
  nning2/transmission-rss:v1.2.1
```

Configuration
-------------

A yaml formatted config file is expected at `/etc/transmission-rss.conf`. Users
can override some options for their transmission-rss instances by providing a
config at `~/.config/transmission-rss/config.yml` (or in `$XDG_CONFIG_HOME`
instead of `~/.config`).

**WARNING:** If you want to override a nested option like `log.target` you also
have to explicitly specify the others like `log.level`. (True for categories
`server`, `login`, `log`, `privileges`, and `client`.)

### Minimal example

It should at least contain a list of feeds:

```yaml
feeds:
  - url: http://example.com/feed1
  - url: http://example.com/feed2
```

Feed item titles can be filtered by a regular expression:

```yaml
feeds:
  - url: http://example.com/feed1
    regexp: foo
  - url: http://example.com/feed2
    regexp: (foo|bar)
```

Feeds can also be configured to download files to specific directory:


```yaml
feeds:
  - url: http://example.com/feed1
    download_path: /home/user/Downloads
```

Setting the seed ratio limit is supported per feed:


```yaml
feeds:
  - url: http://example.com/feed1
    seed_ratio_limit: 0
```

Configurable certificate validation, good for self-signed certificates. Default
is true:


```yaml
feeds:
  - url: http://example.com/feed1
    validate_cert: false
```

Using the GUID instead of the link for tracking seen torrents is also available,
useful for changing URLs such as Prowlarr's proxy links. Default is false:

```yaml
feeds:
  - url: http://example.com/feed1
    seen_by_guid: true
```

### All available options

The following configuration file example contains every existing option
(although `update_interval`, `add_paused`, `server`, `log`, `fork`, `single`, and
`pid_file` are default values and could be omitted). The default `log.target` is
STDERR. `privileges` is not defined by default, so the script runs as current
user/group. `login` is also not defined by default. It has to be defined, if
transmission is configured for HTTP basic authentication.

See `./transmission-rss.conf.example` for more documentation.


```yaml
feeds:
  - url: http://example.com/feed1
  - url: http://example.com/feed2
  - url: http://example.com/feed3
    regexp: match1
  - url: http://example.com/feed4
    regexp: (match1|match2)
  - url: http://example.com/feed5
    download_path: /home/user/Downloads
  - url: http://example.com/feed6
    seed_ratio_limit: 1
  - url: http://example.com/feed7
    regexp:
      - match1
      - match2
  - url: http://example.com/feed8
    regexp:
      - matcher: match1
        download_path: /home/user/match1
      - matcher: match2
        download_path: /home/user/match2
  - url: http://example.com/feed9
    validate_cert: false
    seen_by_guid: true

update_interval: 600

add_paused: false

server:
  host: localhost
  port: 9091
  tls: false
  rpc_path: /transmission/rpc

login:
  username: transmission
  password: transmission

log:
  target: /var/log/transmissiond-rss.log
  level: debug

privileges:
  user: nobody
  group: nobody

client:
  timeout: 5

fork: false

single: false

pid_file: false

seen_file: ~/.config/transmission/seen
```

Daemonized Startup
------------------

### As a systemd service

The following content can be saved into
`/etc/systemd/system/transmission-rss.service` to create a systemd unit.
Remember checking the path in `ExecStart`.

```ini
[Unit]
Description=Transmission RSS daemon.
After=network.target transmission-daemon.service

[Service]
Type=forking
ExecStart=/usr/local/bin/transmission-rss -f
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
```

The unit files are reloaded by `systemctl daemon-reload`. You can then start
transmission-rss by running `systemctl start transmission-rss`. Starting on
boot, can be enabled `systemctl enable transmission-rss`.

### As a cronjob

`transmission-rss` can also be started in a single run mode, in which it runs a single loop and then exits. To do so, `transmission-rss` needs to be started with the `-s` flag. An example crontab line for running every 10 minutes can be:

`*/10 * * * * /usr/local/bin/transmission-rss -s`
