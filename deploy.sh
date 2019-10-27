#!/bin/sh

docker run \
  --volume "$(pwd):/workdir" \
  --workdir "/workdir" \
  --env "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
  --env "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
  --rm \
  --tty \
  timbru31/ruby-node:2.5 \
    /bin/bash -c 'bundle install; bundle exec middleman s3_sync'
