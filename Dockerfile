FROM alpine

RUN apk add \
  --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  hugo=0.152.2-r2

EXPOSE 1313
