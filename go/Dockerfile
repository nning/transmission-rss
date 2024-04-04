# docker build . -f go/Dockerfile -t transmission-rss --no-cache
# touch config.yml seen && docker run -v ./config.yml:/config.yml -v ./seen:/seen transmission-rss

FROM golang:alpine as build
RUN apk add --no-cache git make build-base upx
COPY . .
RUN make clean release

FROM scratch
COPY --from=build /go/cmd/transmission-rss/transmission-rss /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT [ "/transmission-rss" ]
