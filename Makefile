NAME = registry.evertrue.com/evertrue/passenger
VERSION = 0.2.1

.PHONY: all build_all \
		build_ruby_22 build_ruby23 build_full \
		tag_latest release clean_images

all: build_all

build_all: \
	build_ruby22 \
	build_ruby23 \
	build_full

build_ruby22:
	docker build -t $(NAME)-ruby22:$(VERSION) -f Dockerfile-ruby22 .

build_ruby23:
	docker build -t $(NAME)-ruby23:$(VERSION) -f Dockerfile-ruby23 .

build_full:
	docker build -t $(NAME)-full:$(VERSION) -f Dockerfile-full .

tag_latest:
	docker tag $(NAME)-ruby22:$(VERSION) $(NAME)-ruby22:latest
	docker tag $(NAME)-ruby23:$(VERSION) $(NAME)-ruby23:latest
	docker tag $(NAME)-full:$(VERSION) $(NAME)-full:latest

release: tag_latest
	@if ! docker images $(NAME)-ruby22 | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)-ruby22 version $(VERSION) is not yet built. Please run 'make build_ruby22'"; false; fi
	@if ! docker images $(NAME)-ruby23 | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)-ruby23 version $(VERSION) is not yet built. Please run 'make build_ruby23'"; false; fi
	@if ! docker images $(NAME)-full | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)-full version $(VERSION) is not yet built. Please run 'make build_full'"; false; fi
	docker push $(NAME)-ruby22
	docker push $(NAME)-ruby23
	docker push $(NAME)-full
	git tag v$(VERSION) && git push --tags"

clean_images:
	docker rmi $(NAME)-ruby22:latest $(NAME)-ruby22:$(VERSION) || true
	docker rmi $(NAME)-ruby23:latest $(NAME)-ruby23:$(VERSION) || true
	docker rmi $(NAME)-full:latest $(NAME)-full:$(VERSION) || true
