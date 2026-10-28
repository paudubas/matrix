#!/usr/bin/env bash
# First-time setup for scenario 2. Safe to re-run: it never overwrites an
# existing .env.synapse or synapse-data/homeserver.yaml.
set -euo pipefail
cd "$(dirname "$0")"

command -v docker >/dev/null || { echo "Docker is not installed or not on PATH." >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required." >&2; exit 1; }

if [ ! -f .env.synapse ]; then
  # A database volume keeps the password it was created with; a new password would not match it.
  if docker volume inspect matrix-synapse-demo_synapse-postgres >/dev/null 2>&1; then
    echo "Volume matrix-synapse-demo_synapse-postgres exists but .env.synapse is missing." >&2
    echo "Restore the original .env.synapse, or delete the volume (loses its data) and re-run." >&2
    exit 1
  fi
  (umask 077
   printf 'SYNAPSE_DB_PASSWORD=%s\nSYNAPSE_REGISTRATION_SECRET=%s\n' \
     "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env.synapse)
  echo "Created .env.synapse"
fi

mkdir -p synapse-data/conf.d
cp postgres.yaml.template synapse-data/conf.d/postgres.yaml.template

if [ ! -f synapse-data/homeserver.yaml ]; then
  docker compose --env-file .env.synapse run --rm --no-deps --entrypoint /start.py synapse generate
fi

cat <<'EOF'

Setup done. Next:
  docker compose --env-file .env.synapse up -d
  curl http://localhost:8018/_matrix/client/versions
Then create the admin (see README).
EOF
