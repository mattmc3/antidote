.DEFAULT_GOAL := help

.PHONY: test
test:
	./bin/runtests

.PHONY: help
help:
	@echo "Usage:  make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  help  shows this message"
	@echo "  test  run unit tests"
