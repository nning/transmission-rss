# docker build -t transmission-rss .
# docker build -t transmission-rss --build-arg UID=1337 --build-arg GID=1337 .
# docker run -it -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf transmission-rss

FROM ruby:alpine
MAINTAINER henning mueller <mail@nning.io>

ARG UID=1000
ARG GID=1000

RUN \
  addgroup -g $GID ruby && \
  adduser -u $UID -G ruby -D ruby && \
  apk --no-cache --update add build-base libffi-dev

WORKDIR home/ruby
COPY . transmission-rss
RUN chown -R ruby:ruby transmission-rss

USER ruby

WORKDIR transmission-rss
RUN bundle

CMD ./bin/transmission-rss
