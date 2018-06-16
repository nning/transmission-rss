# docker build -t transmission-rss .
# docker build -t transmission-rss --build-arg UID=1337 --build-arg GID=1337 .
# docker run -it -v $(pwd)/transmission-rss.conf:/etc/transmission-rss.conf transmission-rss

FROM ruby:latest
MAINTAINER henning mueller <mail@nning.io>

ARG UID=1000
ARG GID=1000

RUN \
  useradd -m ruby && \
  sed -i "s/1000:1000/$UID:$GID/" /etc/passwd && \
  sed -i "s/1000/$GID/" /etc/group && \
  chown -R ruby:ruby /home/ruby

WORKDIR home/ruby
ADD . transmission-rss
RUN chown -R ruby:ruby transmission-rss

USER ruby
WORKDIR transmission-rss
RUN bundle

CMD ./bin/transmission-rss
