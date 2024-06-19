# Build:
#   docker build -t discourse/ruby:3.3-bookworm-slim --build-arg DEBIAN_RELEASE=bookworm --build-arg RUBY_VERSION=3.3.3 .
#
# You are not expected to build and push this Docker image by hand. This is done by the `build` Github Actions workflow.
ARG DEBIAN_RELEASE=
ARG RUBY_VERSION=

FROM debian:${DEBIAN_RELEASE}-slim

ARG RUBY_VERSION

ENV RUBY_VERSION=${RUBY_VERSION}

# Installs system dependencies required to run Ruby
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    libgmp-dev \
    libssl-dev \
    libyaml-dev \
    procps \
    zlib1g-dev \
    ; \
  # skip installing gem documentation
  mkdir -p /usr/local/etc; \
  { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc; \
  # Installs the dependencies required to build Ruby
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get install -y --no-install-recommends \
    git \
    dpkg-dev \
    libgdbm-dev \
    ruby \
    autoconf \
    g++ \
    gcc \
    libbz2-dev \
    libgdbm-compat-dev \
    libglib2.0-dev \
    libncurses-dev \
    libxml2-dev \
    libxslt-dev \
    make \
    wget \
    xz-utils \
    ; \
  # Install Rust to build Ruby with YJIT
  rustArch=; \
  dpkgArch="$(dpkg --print-architecture)"; \
  case "$dpkgArch" in \
    'amd64') rustArch='x86_64-unknown-linux-gnu'; rustupUrl='https://static.rust-lang.org/rustup/archive/1.26.0/x86_64-unknown-linux-gnu/rustup-init'; rustupSha256='0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db' ;; \
    'arm64') rustArch='aarch64-unknown-linux-gnu'; rustupUrl='https://static.rust-lang.org/rustup/archive/1.26.0/aarch64-unknown-linux-gnu/rustup-init'; rustupSha256='673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800' ;; \
  *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
  esac; \
  mkdir -p /tmp/rust; \
  wget -O /tmp/rust/rustup-init "$rustupUrl"; \
  echo "$rustupSha256 */tmp/rust/rustup-init" | sha256sum --check --strict; \
  chmod +x /tmp/rust/rustup-init; \
  export RUSTUP_HOME='/tmp/rust/rustup' CARGO_HOME='/tmp/rust/cargo'; \
  export PATH="$CARGO_HOME/bin:$PATH"; \
  /tmp/rust/rustup-init -y --no-modify-path --profile minimal --default-toolchain '1.77.0' --default-host "$rustArch"; \
  rustc --version; \
  cargo --version; \
  # Install Ruby with https://github.com/rbenv/ruby-build
  mkdir /src; \
  git -C /src clone https://github.com/rbenv/ruby-build.git; \
  cd /src/ruby-build && ./install.sh; \
  cd / && rm -fr /src; \
  export RUSTUP_HOME='/tmp/rust/rustup' CARGO_HOME='/tmp/rust/cargo';\
  export PATH="$CARGO_HOME/bin:$PATH"; \
  CONFIGURE_OPTS="--disable-install-doc --enable-yjit" ruby-build ${RUBY_VERSION} /usr/local; \
  # Cleanup build dependencies
  rm -rf /tmp/rust; \
  rm -rf /usr/local/bin/ruby-build; \
  rm -rf /var/lib/apt/lists/*; \
  apt-mark auto '.*' > /dev/null; \
  apt-mark manual $savedAptMark > /dev/null; \
  find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
    ; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  # verify we have no "ruby" packages installed
  if dpkg -l | grep -i ruby; then exit 1; fi; \
  [ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; \
  # Disable system libffi for `ffi` gem because it currently doesn't work with Debian Bookworm's FFI
  # See https://github.com/ffi/ffi/issues/1036
  bundle config build.ffi --disable-system-libffi; \
  # rough smoke test
  ruby --version; \
  gem --version; \
  bundle --version
