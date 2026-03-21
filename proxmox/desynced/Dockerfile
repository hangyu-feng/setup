FROM steamcmd/steamcmd:ubuntu-24

USER root

# Enable 32-bit support and install Wine + Xvfb (virtual display for Wine)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wine \
        wine32:i386 \
        winbind \
        xvfb \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Desynced Dedicated Server — copied from /opt/desynced-files on host
ARG INSTALL_DIR=/opt/desynced

COPY desynced-files/ ${INSTALL_DIR}/

WORKDIR ${INSTALL_DIR}

# /desynced/server is mounted for saves and server config
VOLUME ["/desynced/server"]

# UDP game port
EXPOSE 10099/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
