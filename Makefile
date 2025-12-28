HUGO_IMAGE=hugo

all: build

.PHONY: docker
docker:
	docker build --tag $(HUGO_IMAGE) .

.PHONY: build
build: docker
	docker run \
		--rm \
		--tty \
		--env HUGO_ENV=production \
		--volume=$(PWD):/src \
		--entrypoint=hugo \
		--workdir=/src \
		--publish=1313:1313 \
		$(HUGO_IMAGE) \
			--minify

.PHONY: serve
# TODO: livereload does not work
serve: docker
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		--entrypoint=hugo \
		--workdir=/src \
		--publish=1313:1313 \
		$(HUGO_IMAGE) \
			server \
				--bind 0.0.0.0

.PHONY: new
new:
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume=$(PWD):/src \
		--entrypoint=hugo \
		--workdir=/src \
		$(HUGO_IMAGE) \
			new content/blog/$(shell date +%Y-%m-%d)-$(title).md --kind default
