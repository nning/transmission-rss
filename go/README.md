# transmission-rss

transmission-rss is basically a workaround for transmission's lack of the
ability to monitor RSS feeds and automatically add enclosed torrent links.

It works with transmission-daemon and transmission-gtk (if the web frontend
is enabled in the settings dialog). Sites like showrss.info and ezrss.it or
self-hosted seriesly instances are suited well as feed sources.

## Installation

### From Source

Requirements: `golang`, `git`, `make`

    git clone https://github.com/nning/transmission-rss.git
    cd transmission-rss
    make

The `transmission-rss` binary will end up in
`./cmd/transmission-rss/transmission-rss`.

## Configuration

A YAML configuration file is expected in one of the following locations:

- `config.yml` or `transmission-rss.yml` (extension might as well be `.conf` or
  `.yaml`)
- Searched for in the current work directory, the directory the binary is in,
  and the `XDG_CONFIG_HOME` directory (e.g. `~/.config`).

An example configuration is in `go/config.yml.example`.

A minimal configuration for Transmission running on localhost looks like this:

    feeds:
      - url: https://showrss.info/user/231890.rss

## Additional Documentation

- https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md
