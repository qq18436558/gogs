FROM golang:1.15.6-alpine3.12 AS binarybuilder
RUN apk --no-cache --no-progress add --virtual \
  build-deps \
  build-base \
  git \
  linux-pam-dev

WORKDIR /gogs.io/gogs
COPY . .
RUN make build TAGS="cert pam"

FROM alpine:3.12.3
ADD https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64 /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu \
  && echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache --no-progress add \
  bash \
  ca-certificates \
  curl \
  git \
  linux-pam \
  openssh \
  s6 \
  shadow \
  socat \
  tzdata \
  rsync

ENV GOGS_CUSTOM /data/gogs

# Configure LibC Name Service
COPY docker/nsswitch.conf /etc/nsswitch.conf

WORKDIR /app/gogs
COPY docker ./docker
COPY --from=binarybuilder /gogs.io/gogs/gogs .

RUN ./docker/finalize.sh

# Configure Docker Container
VOLUME ["/data", "/backup"]
EXPOSE 3000
ENTRYPOINT ["/app/gogs/docker/start.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
