FROM steamcmd/steamcmd:ubuntu-24

USER root

# Install 64-bit Wine + Xvfb (virtual display for Wine)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wine64 \
        winbind \
        xvfb \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Desynced Dedicated Server — App ID 2943070
ARG STEAM_APP_ID=2943070
ARG INSTALL_DIR=/opt/desynced
ARG STEAM_USER
ARG STEAM_PASS

RUN steamcmd \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir ${INSTALL_DIR} \
    +login ${STEAM_USER} ${STEAM_PASS} \
    +app_update ${STEAM_APP_ID} validate \
    +quit

WORKDIR ${INSTALL_DIR}

# /desynced/server is mounted for saves and server config
VOLUME ["/desynced/server"]

# UDP game port
EXPOSE 10099/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
