# Matrix IaC Hackathon — Participant Guide

Updated: 28 October 2026 · @Paulina

## Welcome

Today, 16:00–19:00 CET, online. Pick a way to run a Matrix homeserver, get it
running, and log in with a client. No rules — anything goes, and questions are
welcome at any level.

- Event room: [#mom-tech-talks:matrix.org](https://matrix.to/#/#mom-tech-talks:matrix.org)
- 16:00 — Kick-off and choose a track
- 16:15 — Hack; post in the event room when you get stuck
- 17:30 — Check-in: who has a server answering?
- 18:30 — Show and tell
- 19:00 — Wrap-up

The goal is a homeserver you can log in to with Element. If you have a public
domain, try federation too. A local server is a good result; it is not publicly
federated just because its client works.

## Scenarios

Each scenario has its own folder with a README (how to run, operate and clean up).

| # | Folder | Option | Server / client URL | Status |
|---|---|---|---|---|
| 1 | [01-docker-tuwunel](01-docker-tuwunel/README.md) | Docker: Tuwunel | `http://localhost:8008` / Element `http://localhost:8080` | Running |
| 2 | [02-docker-synapse](02-docker-synapse/README.md) | Docker: Synapse + PostgreSQL | `http://localhost:8018` / Element `http://localhost:8083` | Running |
| 3 | [03-ess-rancher](03-ess-rancher/README.md) | Helm: ESS Community on Rancher Desktop | `https://chat.ess.localhost` (`admin` / `hackathon-2026`) | Running; local certificate must be trusted |
| 4 | [04-hetzner-terraform](04-hetzner-terraform/README.md) | Terraform: Tuwunel on Hetzner | `http://49.13.150.188:8008` | Running; about €5.49/month before VAT |
| 5 | [05-bare-metal](05-bare-metal/README.md) | Native Tuwunel (systemd, no Docker) | `http://178.105.190.29:8008` | Running on a second Hetzner VM; the script also works on an old PC or a dedicated server (none ordered) |
| Extra | [extra-kind-synapse](extra-kind-synapse/README.md) | Synapse on a local kind cluster | `http://localhost:8009` / Element `http://localhost:8082` | Running; not ESS |

Scenarios 4 and 5 share one Terraform state (in `04-hetzner-terraform/`); the two
VMs cost about €11/month before VAT, and `terraform destroy` there removes both.
Both Hetzner servers accept connections only from the configured client IP and
use plain HTTP, so use disposable accounts.

## Before you start

- Join the event room. Open [Element](https://app.element.io), sign in with a
  Matrix account (or create one on matrix.org), and join
  `#mom-tech-talks:matrix.org`.
- Pick your host: laptop with Docker, local Kubernetes, cloud VM, or spare PC.
- Install the tools for your track; assume nothing is installed. Each scenario
  README has an "Install first" section:

  | Scenario | Install |
  |---|---|
  | 1, 2 | Docker Desktop (with Compose) |
  | 3 | Rancher Desktop, `kubectl`, `helm` |
  | 4 | Terraform, a Hetzner Cloud account and API token |
  | 5 | `ssh`, a USB-stick writer, Debian/Ubuntu Server ISO (or Terraform for the VM) |
  | Extra | Docker, `kind`, `kubectl`, `helm` |

  On macOS everything installs with Homebrew (`brew install ...`); Linux and
  Windows links are in each README.
- A domain is optional. Localhost demos do not provide public federation.

**Choose the server name before registering accounts.** It becomes part of
every Matrix ID (`@you:server.name`) and cannot be changed later. These demos
use different server names and have separate accounts and databases.

## What to run

- **Tuwunel** — lightweight Rust homeserver: `ghcr.io/matrix-construct/tuwunel`.
- **Synapse** — Element's reference homeserver: `ghcr.io/element-hq/synapse`.
- **ESS Community** — Element's integrated Kubernetes stack. See the
  [official ESS Helm guide](https://github.com/element-hq/ess-helm).
- **Element Web** — browser client: `ghcr.io/element-hq/element-web`.
- **matrix-docker-ansible-deploy** — Ansible playbook for a fuller VM or
  bare-metal setup.

Avoid Dimension and mxisd/ma1sd; they are unmaintained. Conduwuit was archived;
use Tuwunel for a new deployment. Treat demo servers as disposable, but keep
your data directories and volumes until you intentionally remove them.

## Public access: TLS and federation

The local demos are for local testing, not public federation. For a public server:

- Choose a domain you control and set the homeserver name before registering.
- Put a maintained reverse proxy such as Caddy in front of the homeserver.
- Use HTTPS for clients and configure `/.well-known/matrix/server` for
  federation.
- Restrict registration; never use the workshop's demo passwords or tokens on
  a public service.
- Test federation with the Matrix federation tester only after DNS, TLS, and
  delegation are correct.

## Troubleshooting

| Symptom | Check |
|---|---|
| Element cannot connect | Run `curl http://<homeserver>/_matrix/client/versions`; verify the URL and that its container, service, and port-forward are running. |
| Docker says container name is already in use | Inspect with `docker ps -a`; start the existing container or choose a different name. Don't remove its data volume to fix a name conflict. |
| Synapse container exits | In `02-docker-synapse/`, run `docker compose --env-file .env.synapse logs synapse`; confirm the base config exists and Postgres is healthy. |
| Synapse cannot authenticate to Postgres | Preserve the original `.env.synapse` values; the database volume was initialized with that password. |
| Kubernetes command targets the wrong cluster | Check `kubectl config current-context` and pass the intended context or kubeconfig explicitly (`extra-kind-synapse/kubeconfig` for the kind cluster). |
| ESS local hostname does not work | Check the Rancher Kubernetes context, ingress controller, hostnames and chart readiness; `.localhost` does not use public DNS or Let's Encrypt. |
| Federation fails | Check public DNS, HTTPS, port 443, and `/.well-known/matrix/server`; a local-only setup cannot federate. |
| Large public room takes time to join | Initial room-state synchronization can take a while; start with a small room. |

## Show and tell

At 18:30, share your scenario, server name, client URL, one thing that worked,
and one thing that broke. Do not share passwords, API tokens, registration
secrets, or Terraform state.

## Sources

- [Element Server Suite Community Helm chart](https://github.com/element-hq/ess-helm)
- [Synapse documentation](https://matrix-org.github.io/synapse/latest/)
- [Tuwunel](https://github.com/matrix-construct/tuwunel)
- [Element Web](https://github.com/element-hq/element-web)
- [matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy)
