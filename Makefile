SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

.PHONY: publish test

publish:
	./Scripts/build_and_publish.py

test:
	./Scripts/test-sign-and-notarize-app.sh
