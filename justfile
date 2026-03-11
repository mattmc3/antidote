# antidote - the cure to slow zsh plugin management

set shell := ["zsh", "-c"]

# display this justfile's help information
[private]
default:
    @just --list

# run build tasks (man pages, tests)
build:
    ./tools/buildman
    ./tools/run-clitests

# rebuild man pages
buildman:
    ./tools/buildman

# build and bump revision version
release:
    ./tools/buildman
    ./tools/run-clitests
    ./tools/bumpver revision

# run only unittests (env: "latest", "542", or "local")
test env="latest":
    #!/usr/bin/env zsh
    if [[ "{{env}}" == "local" ]]; then
        ./tools/run-clitests --unit
    elif [[ "{{env}}" == "542" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh542 \
          /usr/local/bin/zsh -c 'cd /workspace && just test local'
    elif [[ "{{env}}" == "latest" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh-latest \
          /bin/zsh -c 'cd /workspace && just test local'
    else
        print -ru2 "just: invalid env '{{env}}' — expected 'latest', '542', or 'local'"
        exit 1
    fi

# run all tests (env: "latest", "542", or "local")
test-all env="latest":
    #!/usr/bin/env zsh
    if [[ "{{env}}" == "local" ]]; then
        ./tools/run-clitests
    elif [[ "{{env}}" == "542" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh542 \
          /usr/local/bin/zsh -c 'cd /workspace && just test-all local'
    elif [[ "{{env}}" == "latest" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh-latest \
          /bin/zsh -c 'cd /workspace && just test-all local'
    else
        print -ru2 "just: invalid env '{{env}}' — expected 'latest', '542', or 'local'"
        exit 1
    fi

# run only test_real.md (env: "latest", "542", or "local")
test-real env="latest":
    #!/usr/bin/env zsh
    if [[ "{{env}}" == "local" ]]; then
        ./tools/run-clitests tests/test_real.md
    elif [[ "{{env}}" == "542" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh542 \
          /usr/local/bin/zsh -c 'cd /workspace && just test-real local'
    elif [[ "{{env}}" == "latest" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh-latest \
          /bin/zsh -c 'cd /workspace && just test-real local'
    else
        print -ru2 "just: invalid env '{{env}}' — expected 'latest', '542', or 'local'"
        exit 1
    fi

# profile antidote operations with zprof (env: "latest", "542", or "local")
profile env="latest":
    #!/usr/bin/env zsh
    if [[ "{{env}}" == "local" ]]; then
        ./tools/antidote-profile
    elif [[ "{{env}}" == "542" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh542 \
          /usr/local/bin/zsh -c 'cd /workspace && ./tools/antidote-profile'
    elif [[ "{{env}}" == "latest" ]]; then
        podman run --rm -v "$PWD:/workspace:z" antidote-zsh-latest \
          /bin/zsh -c 'cd /workspace && ./tools/antidote-profile'
    else
        print -ru2 "just: invalid env '{{env}}' — expected 'latest', '542', or 'local'"
        exit 1
    fi

# bump the major version (X.0.0)
bump-maj:
    ./tools/bumpver major

# bump the minor version (0.X.0)
bump-min:
    ./tools/bumpver minor

# bump the revision version (0.0.X)
bump-rev:
    ./tools/bumpver revision

# start podman machine and build all test containers
container-up:
    podman machine start 2>/dev/null || true
    just container-build
    just container-build 542

# build a test container (use '542' for Zsh 5.4.2)
container-build zshver="latest":
    #!/usr/bin/env zsh
    if [[ "{{zshver}}" == "542" ]]; then
        podman build -f Dockerfile.542 -t antidote-zsh542 .
    else
        podman build -t antidote-zsh-latest .
    fi

# force-remove and rebuild a test container (use '542' for Zsh 5.4.2)
container-rebuild zshver="latest":
    #!/usr/bin/env zsh
    if [[ "{{zshver}}" == "542" ]]; then
        podman rmi -f antidote-zsh542 2>/dev/null || true
        podman build -f Dockerfile.542 -t antidote-zsh542 .
    else
        podman rmi -f antidote-zsh-latest 2>/dev/null || true
        podman build -t antidote-zsh-latest .
    fi

# open a shell in a test container (use '542' for Zsh 5.4.2)
container-shell zshver="latest":
    #!/usr/bin/env zsh
    image="antidote-zsh-latest"
    [[ "{{zshver}}" == "542" ]] && image="antidote-zsh542"
    podman run -it --rm -v "$PWD:/workspace:z" "$image"
