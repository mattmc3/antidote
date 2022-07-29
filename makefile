.DEFAULT_GOAL := help

.PHONY: test
test:
	./tests/runtests

.PHONY: major
major:
	bumpversion major
	git add .
	git commit -m "Bump major version number"

.PHONY: minor
minor:
	bumpversion minor
	git add .
	git commit -m "Bump minor version number"

.PHONY: rev
rev:
	bumpversion revision
	git add .
	git commit -m "Bump revision version number"

.PHONY: help
help:
	@echo "Usage:  make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  help  shows this message"
	@echo "  test  run unit tests"
