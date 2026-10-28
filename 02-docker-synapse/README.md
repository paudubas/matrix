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

## Quick start (in this order)

From the repo root:

```bash
cd 02-docker-synapse
./setup.sh                                   # 1. creates .env.synapse (secrets) and synapse-data/ (config); starts nothing
docker compose --env-file .env.synapse up -d # 2. starts Postgres, Synapse, Element
docker compose --env-file .env.synapse ps    # 3. wait until synapse shows "healthy"
docker compose --env-file .env.synapse exec -it synapse register_new_matrix_user -c /data/homeserver.yaml -c /tmp/postgres.yaml -u admin -a http://localhost:8008   # 4. create the admin
```

Then sign in at <http://localhost:8083>. `exec` only works on a running stack, so step 2 must come before step 4. Details follow below.

## Create the admin

Use the demo password `hackathon-2026` when prompted (or run the VS Code task *Create Docker Synapse admin*).

```bash
docker compose --env-file .env.synapse exec -it synapse \
  register_new_matrix_user -c /data/homeserver.yaml -c /tmp/postgres.yaml \
  -u admin -a http://localhost:8008
```

Then sign in at <http://localhost:8083> (Matrix ID `@admin:matrix.synapse.test`).

**Paths:** the command runs inside the container, where `./synapse-data` (your laptop) is mounted as `/data`. So `/data/homeserver.yaml` in the command is `synapse-data/homeserver.yaml` on disk. `/tmp/postgres.yaml` exists only inside the container; it is generated at start from the template and `.env.synapse`.

Type the command on one line, or end every line except the last with `\` and nothing after it; otherwise the shell runs each line separately.

Run it from this folder, and only once synapse shows `healthy` in `docker compose --env-file .env.synapse ps`.

**`User ID already taken`?** The admin already exists, so just sign in. Accounts live in the Postgres volume (`matrix-synapse-demo_synapse-postgres`), not in `synapse-data/`, which holds only config, keys and media. Deleting `synapse-data/` does not remove accounts; for an empty server use the full reset below (`down -v`).

## Operate

```bash
curl http://localhost:8018/_matrix/client/versions
docker compose --env-file .env.synapse ps
docker compose --env-file .env.synapse logs synapse
docker compose --env-file .env.synapse down    # keeps the database

# Full reset (deletes database and accounts), then run ./setup.sh again
docker compose --env-file .env.synapse down -v --remove-orphans
rm -rf synapse-data .env.synapse
```

Do **not** add `-v` unless you want to delete the PostgreSQL volume. Never regenerate `.env.synapse` after the database exists; Postgres needs the original password.

## Troubleshooting: "service synapse is not running"

Look at why it stopped (from this folder):

```bash
docker compose --env-file .env.synapse ps -a
docker compose --env-file .env.synapse logs --tail 50 synapse
```

The usual cause is a leftover database volume with an old password (`password authentication failed`) or a deleted `synapse-data/` or `.env.synapse`. Reset everything and start clean:

```bash
docker compose --env-file .env.synapse down -v --remove-orphans
rm -rf synapse-data .env.synapse
./setup.sh && docker compose --env-file .env.synapse up -d
```

If `.env.synapse` is already gone and `down -v` fails, run `docker volume rm matrix-synapse-demo_synapse-postgres` first.

Once synapse shows `healthy` in `ps`, create the admin (one line, no backslashes):

```bash
docker compose --env-file .env.synapse exec -it synapse register_new_matrix_user -c /data/homeserver.yaml -c /tmp/postgres.yaml -u admin -a http://localhost:8008
```

## Fresh clone: run setup first

`.env.synapse` and `synapse-data/` are git-ignored, so they don't exist after `git clone`, and every `docker compose` command below fails until you create them. Run once, from this folder:

```bash
cd 02-docker-synapse
./setup.sh
docker compose --env-file .env.synapse up -d
```

`setup.sh` creates `.env.synapse` with random secrets, installs `postgres.yaml.template`, and generates the Synapse config. It is safe to re-run and never overwrites an existing `.env.synapse` or config. If the Postgres volume already exists but `.env.synapse` is missing, it stops: the volume keeps its original password, so restore the original file or delete the volume (this loses its data). Then create the admin as above.
