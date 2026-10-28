# 2 — Docker: Synapse + PostgreSQL

Server `http://localhost:8018` · Element `http://localhost:8083` · server name `matrix.synapse.test` (admin `@admin:matrix.synapse.test`).

Secrets (`.env.synapse`) and generated config (`synapse-data/`) are git-ignored, so after a fresh clone run [`./setup.sh`](#fresh-clone-run-setup-first) first. Run all commands from this folder.

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

## Fresh clone: run setup first

`.env.synapse` and `synapse-data/` are git-ignored, so they don't exist after `git clone`, and every `docker compose` command below fails until you create them. Run once, from this folder:

```bash
cd 02-docker-synapse
./setup.sh
docker compose --env-file .env.synapse up -d
```

`setup.sh` creates `.env.synapse` with random secrets, installs `postgres.yaml.template`, and generates the Synapse config. It is safe to re-run and never overwrites an existing `.env.synapse` or config. If the Postgres volume already exists but `.env.synapse` is missing, it stops: the volume keeps its original password, so restore the original file or delete the volume (this loses its data). Then create the admin as above.
