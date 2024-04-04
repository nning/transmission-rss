# transmission-rss

transmission-rss is basically a workaround for transmission's lack of the
ability to monitor RSS feeds and automatically add enclosed torrent links.

It works with transmission-daemon and transmission-gtk (if the web frontend
is enabled in the settings dialog). Sites like showrss.karmorra.info and
ezrss.it or self-hosted seriesly instances are suited well as feed sources.

## Installation

### From Source

Install `golang` and `make` on your machine.

    git clone https://github.com/nning/transmission-rss.git
    cd transmission-rss
    make

The `transmission-rss` binary will end up in
`./cmd/transmission-rss/transmission-rss`.

The binary size is optimized aggressively. If you encounter compatibility issues
when cross-compiling for another machine, compile with
`make clean build CGO_ENABLED=0`.

## Additional Documentation

- https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md
