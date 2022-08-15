.DEFAULT_GOAL := help
all : test testall testreal bumpmaj bumpmin bumprev help
.PHONY : all

build:
	./tools/buildman

test:
	./tools/runtests

testall:
	./tools/runtests ./tests/*test_*.zsh

testreal:
	./tools/runtests ./tests/realtest_*.zsh

bumpmaj:
	bumpversion major
	git add .
	git commit -m "Bump major version number"

bumpmin:
	bumpversion minor
	git add .
	git commit -m "Bump minor version number"

bumprev:
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
	@echo "  bumpmaj   bump the major version (X.0.0)"
	@echo "  bumpmin   bump the minor version (0.X.0)"
	@echo "  bumprev   bump the revision ver (0.0.X)"
