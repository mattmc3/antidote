.DEFAULT_GOAL := help
all : build test testall testreal bump-maj bump-min bump-rev help
.PHONY : all

build:
	./tools/buildman

test:
	./tools/runtests

testall:
	./tools/runtests ./tests/*test_*.zsh

testreal:
	./tools/runtests ./tests/realtest_*.zsh

bump-maj:
	./tools/bumpver major

bump-min:
	./tools/bumpver minor

bump-rev:
	./tools/bumpver revision

help:
	@echo "Usage:  make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  help      shows this message"
	@echo "  build     run build tasks like generating man pages"
	@echo "  test      run unit tests"
	@echo "  testreal  run real tests"
	@echo "  testall   run unit tests and real tests"
	@echo "  bump-maj  bump the major version (X.0.0)"
	@echo "  bump-min  bump the minor version (0.X.0)"
	@echo "  bump-rev  bump the revision ver (0.0.X)"
