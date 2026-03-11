FROM alpine:latest

RUN apk add --no-cache \
    zsh \
    bash \
    git \
    just \
    perl \
    mandoc \
    less

# Install clitest (same repo as CI workflow)
RUN git clone --depth=1 https://github.com/aureliojargas/clitest /opt/clitest

ENV PATH="/opt/clitest:$PATH"
ENV ZSH_BINARY="/bin/zsh"

WORKDIR /workspace

CMD ["/bin/zsh"]
