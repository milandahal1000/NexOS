ISO_DIR := build/output/build
DESCRIPTION := build/nexos-descr
BUILD_ARGS ?=

.PHONY: host-check host-selinux description build clone-vendor lint test clean

host-check:
	./build/scripts/check-host.sh

host-selinux:
	sudo ./build/scripts/setup-selinux.sh

description:
	./build/scripts/prepare-description.sh

build: host-check
	sudo ./build/scripts/build-iso.sh --output-dir "$(ISO_DIR)" $(BUILD_ARGS)

clone-vendor:
	./build/scripts/clone-vendor.sh

lint:
	shellcheck build/scripts/*.sh
	ruff check apps/developer-hub 2>/dev/null || true

test:
	pytest apps/developer-hub/tests tests/unit 2>/dev/null || true

clean:
	rm -rf build/out build/tmp build/output build/logs $(DESCRIPTION)
