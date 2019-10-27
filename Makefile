all: build

build:
	./build.sh

dev:
	docker-compose up

deploy:
	./deploy.sh
