IMAGE := mydotfiles-test

.PHONY: test test-build test-shell

test: test-build
	docker run --rm $(IMAGE)

test-build:
	docker build -t $(IMAGE) -f test/Dockerfile .

test-shell: test-build
	docker run --rm -it $(IMAGE) bash
