HUGO_VERSION=0.101.0-ext
HUGO_IMAGE=klakegg/hugo:$(HUGO_VERSION)

all: build

.PHONY: build
build:
	docker run \
		--rm \
		--tty \
		--env HUGO_ENV=production \
		--volume=$(PWD):/src \
		$(HUGO_IMAGE) \
			--minify

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

.PHONY: new
new:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		$(HUGO_IMAGE) \
			new content/blog/$(shell date +%Y-%m-%d)-$(title).md --kind default
