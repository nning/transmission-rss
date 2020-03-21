# docker build -t transmission-rss .
# docker build -t transmission-rss --build-arg UID=1337 --build-arg GID=1337 .
# docker run -it -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf transmission-rss

FROM alpine:3 as builder
RUN apk add gcc libc-dev make ruby-dev
COPY . /tmp
WORKDIR /tmp
RUN \
  gem build transmission-rss.gemspec && \
  gem install -N --build-root /build transmission-rss-*.gem

FROM alpine:3
MAINTAINER henning mueller <mail@nning.io>
ARG UID=1000
ARG GID=1000
RUN \
  addgroup -g $GID ruby && \
  adduser -u $UID -G ruby -D ruby && \
  apk add --no-cache ruby ruby-etc ruby-json
USER ruby
COPY --from=builder /build /
CMD ["transmission-rss"]
