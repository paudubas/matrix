# 2 — Docker: Synapse + PostgreSQL

Server `http://localhost:8018` · Element `http://localhost:8083` · server name `matrix.synapse.test` (admin `@admin:matrix.synapse.test`).

Secrets (`.env.synapse`) and generated config (`synapse-data/`) are git-ignored. Run all commands from this folder.

## Install first

Docker with Compose, and `openssl` (for the secrets on a fresh clone; preinstalled on macOS and most Linux).

```bash
brew install --cask docker     # macOS; open Docker Desktop once and wait until it is running
docker --version && docker compose version && openssl version
```

Linux: <https://docs.docker.com/engine/install/> (with the Compose plugin).

## Create the admin

Use the demo password `hackathon-2026` when prompted (or run the VS Code task *Create Docker Synapse admin*).

```bash
docker compose --env-file .env.synapse exec -it synapse \
  register_new_matrix_user -c /data/homeserver.yaml -c /tmp/postgres.yaml \
  -u admin -a http://localhost:8008
```

Then sign in at <http://localhost:8083>.

## Operate

```bash
curl http://localhost:8018/_matrix/client/versions
docker compose --env-file .env.synapse ps
docker compose --env-file .env.synapse logs synapse
docker compose --env-file .env.synapse down    # keeps the database
```

Do **not** add `-v` unless you want to delete the PostgreSQL volume. Never regenerate `.env.synapse` after the database exists; Postgres needs the original password.

## Fresh clone only

Skip if `.env.synapse` or `synapse-data/homeserver.yaml` already exists. Run from `02-docker-synapse/` (`cd 02-docker-synapse` first), or the secrets file lands in the wrong folder.

```bash
umask 077
printf 'SYNAPSE_DB_PASSWORD=%s\nSYNAPSE_REGISTRATION_SECRET=%s\n' \
  "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env.synapse
docker compose --env-file .env.synapse run --rm --no-deps --entrypoint /start.py synapse generate
docker compose --env-file .env.synapse up -d
```

Then create the admin as above.
