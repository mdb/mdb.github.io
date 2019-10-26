#!/bin/sh

docker run \
  --volume "$(pwd):/workdir" \
  --workdir "/workdir" \
  --rm \
  --tty \
  --interactive \
  timbru31/ruby-node:2.5 \
    /bin/bash -c 'npm install -g bower; bower install --allow-root; bundle install; bundle exec middleman build'
