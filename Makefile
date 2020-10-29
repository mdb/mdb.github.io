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
