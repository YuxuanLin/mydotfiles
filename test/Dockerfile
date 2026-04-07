FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y -qq \
    sudo curl git ca-certificates locales file build-essential procps \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8

RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY --chown=testuser:testuser . /home/testuser/dotfiles

USER testuser
WORKDIR /home/testuser/dotfiles

CMD ["bash", "test/verify.sh"]
