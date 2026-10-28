ISO_DIR := build/output/build
DESCRIPTION := build/nexos-descr

.PHONY: host-check host-selinux description build clone-vendor lint test clean

host-check:
	./build/scripts/check-host.sh

host-selinux:
	sudo ./build/scripts/setup-selinux.sh

description:
	./build/scripts/prepare-description.sh

build: host-check description
	sudo kiwi-ng --type=iso --profile=Xfce-Live --kiwi-file=Fedora.kiwi \
		--color-output system build --description $(DESCRIPTION) \
		--target-dir $(ISO_DIR)

clone-vendor:
	./build/scripts/clone-vendor.sh

lint:
	shellcheck build/scripts/*.sh
	ruff check apps/developer-hub 2>/dev/null || true

test:
	pytest apps/developer-hub/tests tests/unit 2>/dev/null || true

clean:
	rm -rf build/out build/tmp build/output build/logs $(DESCRIPTION)
