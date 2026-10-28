# 1 — Docker: Tuwunel

Server `http://localhost:8008` · Element `http://localhost:8080` · server name `matrix.example.com` (local demo only, not for federation).

## Install first

Only Docker is needed (it includes Compose). A browser is the client.

```bash
brew install --cask docker     # macOS; then open Docker Desktop once and wait until it says "running"
docker --version && docker compose version
```

Linux: follow <https://docs.docker.com/engine/install/> (install the Compose plugin too). Windows: Docker Desktop with WSL2.

## Run

The server is a standalone container named `tuwunel` (volume `tuwunel-db`). **Don't run `docker run --name tuwunel` again** — the name is taken. Inspect or restart it:

```bash
docker ps --filter name=tuwunel
docker start tuwunel
curl http://localhost:8008/_matrix/client/versions
```

Register with the demo token `hackathon-2026`. The first account is the admin.
To use this Tuwunel server from Element, choose the custom homeserver URL
`http://localhost:8008`.

## Element client (this folder)

```bash
cd 01-docker-tuwunel     # from the repo root
docker compose up -d     # start Element on 127.0.0.1:8080
docker compose down      # stop it; Tuwunel keeps running
```

## Cleanup

Stopping Element with `docker compose down` does not stop or delete Tuwunel.
To stop the server but keep its accounts and messages:

```bash
docker stop tuwunel
```

To permanently remove the server and its data, back up anything you need,
then remove the container and database volume:

```bash
docker rm -f tuwunel
docker volume rm tuwunel-db
```

This deletes all accounts and messages stored on this server.

## A fresh Tuwunel server

Use a unique name and volume. Replace the server name for a public deployment and use a private token.

```bash
docker run -d --name tuwunel-new -p 8008:8008 \
  -v tuwunel-new-db:/data \
  -e TUWUNEL_SERVER_NAME="matrix.example.com" \
  -e TUWUNEL_DATABASE_PATH="/data" \
  -e TUWUNEL_ADDRESS="0.0.0.0" \
  -e TUWUNEL_ALLOW_REGISTRATION="true" \
  -e TUWUNEL_REGISTRATION_TOKEN="replace-with-a-private-token" \
  ghcr.io/matrix-construct/tuwunel:latest
```
