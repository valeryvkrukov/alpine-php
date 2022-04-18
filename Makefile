REPO:=val2k/alpine-php
DOCKER_RUN:=docker run --rm -v $(PWD):/app ${REPO}:main
DOCKER_RUN_DEV:=docker run --rm -v $(PWD):/app ${REPO}:dev

build:
	docker build -t $(REPO):main --target main -f php/Dockerfile php/
	docker build -t $(REPO):dev --target dev -f php/Dockerfile php/
run-detached:
	docker run --name php-main -d -v $(PWD):/app $(REPO):main
	docker run --name php-dev -d -v $(PWD):/app $(REPO):dev
test-main:
	$(DOCKER_RUN) php -v
	$(DOCKER_RUN) sh -c "php -v | grep 8.1"
	$(DOCKER_RUN) sh -c "php -v | grep OPcache"
	$(DOCKER_RUN) sh -c "php test/test.php | grep OK"
	$(DOCKER_RUN) sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 256M"
test-dev:
	$(DOCKER_RUN_DEV) sh -c "php -v | grep Xdebug"
	$(DOCKER_RUN_DEV) composer --version
	$(DOCKER_RUN_DEV) sh -c "php test/test.php | grep OK"
	$(DOCKER_RUN_DEV) sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 1G"
release: build
	$(eval export SEMVER=$(shell docker run --rm -v $(PWD):/app ${REPO}:main php -r "echo phpversion();"))
	docker tag ${REPO}:main ${REPO}:${SEMVER}
	docker tag ${REPO}:dev ${REPO}:${SEMVER}-dev
	echo "Releasing: ${REPO}:${SEMVER}"
	echo "Releasing: ${REPO}:${SEMVER}-dev"
	echo "Releasing: ${REPO}:main"
	echo "Releasing: ${REPO}:dev"
	docker push ${REPO}:main
	docker push ${REPO}:${SEMVER}
	docker push ${REPO}:dev
	docker push ${REPO}:${SEMVER}-dev
test-all: test-all
	make build
	make test-main
	make test-dev