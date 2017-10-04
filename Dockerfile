# docker build -t transmission-rss .
# docker run -it -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf transmission-rss

FROM ruby:latest
MAINTAINER henning mueller <mail@nning.io>

RUN useradd -m ruby

WORKDIR home/ruby
ADD . transmission-rss
RUN chown -R ruby:ruby transmission-rss

USER ruby
WORKDIR transmission-rss
RUN bundle

CMD ./bin/transmission-rss
