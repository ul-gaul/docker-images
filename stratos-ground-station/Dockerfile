FROM golang:latest
ARG DEBIAN_FRONTEND='noninteractive'

# Install NodeJS + npm
RUN set +x \
    && curl -sSL 'https://api.github.com/repos/nodesource/distributions/contents/deb' \
        | sed -nE 's/.*"(setup_[0-9]+\.x)".*/\1/ p' \
        | sort -Vr | head -n1 \
        | xargs -I {} curl -sSL 'https://deb.nodesource.com/{}' \
        | bash - \
    && apt-get update -q \
    && apt-get install -yq --no-install-recommends \
        nodejs \
    && npm i -g npm@latest 2>/dev/null

# Install dependencies for cross compile
RUN set -x \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture arm64 \
    && dpkg --add-architecture armel \
    && apt-get update -q \
    && apt-get upgrade -qy \
    && apt-get install -qy --no-install-recommends \
        gcc-mingw-w64 \
        crossbuild-essential-armhf \
        crossbuild-essential-arm64 \
        libwebkit2gtk-4.0-dev \
        libwebkit2gtk-4.0-dev:armhf \
        libwebkit2gtk-4.0-dev:arm64 \
        libgtk-3-dev \
        libgtk-3-dev:armhf \
        libgtk-3-dev:arm64 \
    && apt-get install -qy --no-install-recommends \
        gcc-multilib \
    && apt-get clean -q

COPY ./tools /tools
RUN set +x \
    && chmod +x /tools/*.sh

ENV OUTPUT_DIR='/out'

WORKDIR /app
