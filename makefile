.DEFAULT_GOAL := help
all : test testall testreal major minor rev help
.PHONY : all

build:
	./tools/buildman

test:
	./tools/runtests

testall:
	./tools/runtests ./tests/*test_*.zsh

testreal:
	./tools/runtests ./tests/realtest_*.zsh

major:
	bumpversion major
	git add .
	git commit -m "Bump major version number"

minor:
	bumpversion minor
	git add .
	git commit -m "Bump minor version number"

rev:
	bumpversion revision
	git add .
	git commit -m "Bump revision version number"

help:
	@echo "Usage:  make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  help      shows this message"
	@echo "  test      run unit tests"
	@echo "  testreal  run real tests"
	@echo "  testall   run unit tests and real tests"
	@echo "  major     bump major version (X.0.0)"
	@echo "  minor     bump minor version (0.X.0)"
	@echo "  rev       bump version revision (0.0.X)"
