FROM debian:trixie-slim AS mcrcon-builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates build-essential git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --depth 1 https://github.com/Tiiffi/mcrcon.git \
  && make -C mcrcon \
  && install -m 0755 mcrcon/mcrcon /usr/local/bin/mcrcon

FROM eclipse-temurin:25-jre

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl jq procps tini util-linux \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  existing_group="$(getent group 1000 | cut -d: -f1 || true)"; \
  if [ -n "$existing_group" ] && [ "$existing_group" != "mc" ]; then \
    groupmod --new-name mc "$existing_group"; \
  elif [ -z "$existing_group" ]; then \
    groupadd --gid 1000 mc; \
  fi; \
  existing_user="$(getent passwd 1000 | cut -d: -f1 || true)"; \
  if [ -n "$existing_user" ] && [ "$existing_user" != "mc" ]; then \
    usermod --login mc --home /home/mc --move-home "$existing_user"; \
    usermod --gid 1000 --shell /bin/bash mc; \
  elif [ -z "$existing_user" ]; then \
    useradd --uid 1000 --gid 1000 --create-home --home-dir /home/mc --shell /bin/bash mc; \
  fi; \
  mkdir -p /data /opt/minecraft; \
  chown -R mc:mc /data /opt/minecraft

COPY --chown=mc:mc scripts/ /opt/minecraft/scripts/
COPY --from=mcrcon-builder /usr/local/bin/mcrcon /usr/local/bin/mcrcon

RUN chmod +x /opt/minecraft/scripts/*.sh

USER mc:mc
WORKDIR /data

EXPOSE 25565/tcp 25575/tcp 19132/udp

ENTRYPOINT ["tini", "-g", "--", "/opt/minecraft/scripts/entrypoint.sh"]
CMD ["/opt/minecraft/scripts/start-paper.sh"]
