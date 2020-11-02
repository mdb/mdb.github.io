all: build

.PHONY: build
build:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		klakegg/hugo:0.74.3

.PHONY: serve
# TODO: livereload does not work
serve:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		--publish=1313:1313 \
		klakegg/hugo:0.74.3 \
			server

.PHONY: deploy
deploy:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD)/public:/public \
		--workdir=/ \
		--env=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
		--env=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
		amazon/aws-cli \
			s3 \
				sync \
				"public" \
				"s3://www.mikeball.info" \
				--delete

.PHONY: s3-help
s3-help:
	docker run \
		--rm \
		--tty \
		--interactive \
		amazon/aws-cli \
			s3 \
				help
