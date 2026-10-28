# Extra — Synapse on a local kind cluster

Not one of the five scenarios and not ESS: Synapse, PostgreSQL, Redis and Element on a separate kind cluster `matrix-local`. Homeserver `http://localhost:8009`, Element `http://localhost:8082`, server name `matrix.k8s.test`. The kubeconfig here is git-ignored so your default kubectl context is untouched.

## Install first

Docker, `kind`, `kubectl` and `helm`:

```bash
brew install --cask docker     # open Docker Desktop once and wait until it is running
brew install kind kubectl helm
kind version && kubectl version --client && helm version
```

Linux: <https://docs.docker.com/engine/install/> and <https://kind.sigs.k8s.io/docs/user/quick-start/>.

## Create the cluster and namespace

From the repository root, enter this folder. With Docker running, create the
local cluster if it does not already exist. The command also writes its
connection details to `kubeconfig`; do not create that file by hand.

```bash
cd extra-kind-synapse
kind create cluster --name matrix-local --kubeconfig "$PWD/kubeconfig"
export KUBECONFIG="$PWD/kubeconfig"
kubectl config current-context
```

The context must be `kind-matrix-local`. If the cluster already exists but
its kubeconfig is missing or empty, regenerate it instead of creating another
cluster:

```bash
kind export kubeconfig --name matrix-local --kubeconfig "$PWD/kubeconfig"
```

Create the `matrix` namespace before running any commands with `-n matrix`.
This command is safe to repeat if the namespace already exists:

```bash
kubectl --context kind-matrix-local create namespace matrix --dry-run=client -o yaml \
  | kubectl --context kind-matrix-local apply -f -
```

**This creates only an empty namespace, not the applications.** Synapse,
PostgreSQL, Redis and Element must also be deployed before the commands below
can list pods or forward ports. The application deployment steps are not yet
documented in this guide; creating the namespace alone will still give
`No resources found`.

## Operate

From this folder:

```bash
export KUBECONFIG="$PWD/kubeconfig"
kubectl config current-context
kubectl -n matrix get pods,pvc
kubectl -n matrix port-forward --address 127.0.0.1 service/synapse-matrix-synapse 8009:8008
```

In another terminal with the same `KUBECONFIG`:

```bash
kubectl -n matrix port-forward --address 127.0.0.1 service/element 8082:80
```

Browser registration is disabled; create an admin (or use the VS Code task *Create Kubernetes Matrix admin*):

```bash
kubectl -n matrix exec -it deployment/synapse-matrix-synapse -- \
  register_new_matrix_user \
  -c /synapse/config/homeserver.yaml \
  -c /synapse/config/conf.d/secrets.yaml \
  -a http://localhost:8008
```

## Cleanup

Deleting the cluster permanently deletes its Synapse accounts, messages and
other cluster data (only `matrix-local` is affected). Stop any port-forward
commands with Ctrl-C, then run:

```bash
kind delete cluster --name matrix-local
```
