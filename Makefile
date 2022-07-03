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
