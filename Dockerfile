FROM alpine

RUN apk add \
  --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  hugo=0.157.0-r0

EXPOSE 1313
