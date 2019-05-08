#!/bin/sh

docker run \
  -v $(PWD):/workdir \
  -w /workdir \
  --rm \
  -ti timbru31/ruby-node:2.5 \
  /bin/bash -c 'npm install -g bower; bower install --allow-root; bundle install; bundle exec middleman build'
