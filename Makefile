SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

.PHONY: publish

publish:
	./Scripts/build_and_publish.py
