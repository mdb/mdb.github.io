HUGO_VERSION=0.95.0-ext
HUGO_IMAGE=klakegg/hugo:$(HUGO_VERSION)

all: build

.PHONY: build
build:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		$(HUGO_IMAGE)

.PHONY: serve
# TODO: livereload does not work
serve:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		--publish=1313:1313 \
		$(HUGO_IMAGE) \
			server

.PHONY: deploy
deploy: build
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
