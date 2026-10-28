#!/usr/bin/env bash
# Creates a Matrix user on the Ansible-installed server. The password is
# prompted for and never stored. Run after the playbook install has finished.
#   ./register-user.sh [username] [admin|user]    (default: admin admin)
set -euo pipefail
cd "$(dirname "$0")/matrix-docker-ansible-deploy"

username="${1:-admin}"
role="${2:-admin}"
[ "$role" = admin ] && admin=yes || admin=no

[ -f inventory/hosts ] || { echo "Run the playbook setup first (see README): inventory/hosts is missing." >&2; exit 1; }

read -rsp "Password for ${username}: " password; echo
read -rsp "Repeat password: " again; echo
[ "$password" = "$again" ] && [ -n "$password" ] || { echo "Passwords empty or different." >&2; exit 1; }

ansible-playbook -i inventory/hosts setup.yml \
  --extra-vars "username=${username} password=${password} admin=${admin}" \
  --tags=register-user
