# Minecraft Server Docker Image

This repository builds a Paper Minecraft server image and keeps mutable server state on the host.

## Layout

- `Dockerfile`: Java 25 runtime image with helper scripts.
- `docker-compose.yaml`: Runs the server and mounts host config/runtime data.
- `scripts/`: Paper download, plugin update, entrypoint, and optional Telegram helper scripts.
- `config/root/`: Files mounted directly into the Minecraft working directory.
- `config/paper/`: Mounted as `/data/config`.
- `config/plugins/`: Mounted plugin configuration directories.
- `data/`: Runtime state, worlds, Paper jars, logs, and generated files.

## Run

Review `.env`, then start:

```sh
docker compose up -d --build
```

Put existing worlds under:

```text
data/world
data/world_nether
data/world_the_end
```

## Notes

`RCON_PASSWORD`, `MANAGEMENT_SERVER_SECRET`, `TELEGRAM_BOT_TOKEN`, and `TELEGRAM_CHAT_ID` are read from `.env`. `server.properties` is updated with the secret values when the container starts. `.env` is ignored by Git; `.env.example` documents the required variables.

Geyser and Floodgate jars are downloaded into `data/plugins` on startup when `UPDATE_PLUGINS_ON_START=true`.

`start-paper.sh` also starts the Telegram notification and Telegram-to-Minecraft bridge scripts before launching Paper. They can be disabled with `ENABLE_TELEGRAM_NOTIFY=false` or `ENABLE_TELEGRAM_TO_MC=false`. On container stop, the launcher sends `SIGTERM` to Paper and both helper scripts, then waits for them to exit.

The container runs as user `mc` with UID/GID `1000`, so host-mounted files should be writable by UID `1000`.
