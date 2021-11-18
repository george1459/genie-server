FROM docker.io/debian:10

ARG GENIE_CLIENT_CPP_VERSION=e6d11ea6582883ef74df68a884d87444f63a113b

# Base env settings
ENV LANG="en_US.utf8"

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        gnupg \
        pulseaudio \
        pulseaudio-utils \
        libjson-glib-1.0-0 \
        libevdev2 \
        sound-theme-freedesktop \
        unzip \
        sqlite \
        coreutils \
        ca-certificates \
        zip \
        gstreamer1.0-plugins-base-apps \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-pulseaudio \
    && curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
        | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_12.x buster main" \
        > /etc/apt/sources.list.d/nodesource.list \
    \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs

# Install genie-client
RUN \
    mkdir /src \
    && set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        ninja-build \
        git \
        meson \
        libgstreamer1.0-dev \
        libasound2-dev \
        libglib2.0-dev \
        libjson-glib-dev \
        libsoup2.4-dev \
        libevdev-dev \
        libpulse-dev \
        libspeex-dev \
        libspeexdsp-dev \
        libwebrtc-audio-processing-dev \
    && git clone \
        "https://github.com/stanford-oval/genie-client-cpp" /src \
    && cd /src \
    && git checkout ${GENIE_CLIENT_CPP_VERSION} \
    && ./scripts/get-assets.sh ${BUILD_ARCH} \
    && meson build \
    && ninja -C build \
    && ninja -C build install \
    && apt-get purge -y --auto-remove \
        build-essential \
        pkg-config \
        ninja-build \
        git \
        meson \
        libgstreamer1.0-dev \
        libasound2-dev \
        libglib2.0-dev \
        libjson-glib-dev \
        libsoup2.4-dev \
        libevdev-dev \
        libpulse-dev \
        libspeex-dev \
        libspeexdsp-dev \
        libwebrtc-audio-processing-dev \
    && rm -rf /src

# Copy genie-server files
RUN mkdir /opt/genie-server
RUN useradd -m genie-server && \
   chown genie-server:genie-server /opt/genie-server
USER genie-server
COPY --chown=genie-server:genie-server . /opt/genie-server
WORKDIR /opt/genie-server

# Install dev dependencies
USER root
RUN \
    set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        git \
        nginx \
        python-dev \
        gettext \
        sudo \
        wget \
    && rm -rf /opt/genie-server/node_modules \
    && npm config set unsafe-perm \
    && su genie-server -c 'npm ci' \
    && mkdir -p /home/genie-server/.cache \
    && apt-get purge -y --auto-remove \
        build-essential \
        pkg-config \
        git \
        python-dev \
    \
    && rm -rf \
        /opt/genie-server/.[!.]* \
        /root/.cache \
        /root/.config \
        /home/genie-server/.cache \
        /home/genie-server/.config \
        /tmp/.[!.]* \
        /tmp/* \
        /usr/local/share/.cache \
        /usr/local/share/.config \
        /usr/lib/nginx \
        /var/lib/apt/lists/* \
        /var/www

ENV HOME /home/genie-server
# switch back to root user so we can access the pulseaudio socket
USER root

EXPOSE 3000
ENV THINGENGINE_HOME=/var/lib/genie-server
ENV PULSE_SOCKET=unix:/run/pulse/native

ENTRYPOINT ["npm", "start"]
