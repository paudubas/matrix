# Extra — Synapse on a local kind cluster

Not one of the five scenarios and not ESS: Synapse, PostgreSQL, Redis and Element on a separate kind cluster `matrix-local`. Homeserver `http://localhost:8009`, Element `http://localhost:8082`, server name `matrix.k8s.test`. The kubeconfig here is git-ignored so your default kubectl context is untouched.

## Install first

Docker, `kind`, `kubectl` and `helm`:

```bash
brew install --cask docker     # open Docker Desktop once and wait until it is running
brew install kind kubectl helm
kind version && kubectl version --client && helm version
```

Linux: <https://docs.docker.com/engine/install/> and <https://kind.sigs.k8s.io/docs/user/quick-start/>. The cluster is named `matrix-local`; the manifests here (`synapse-values.yaml`, `backends.yaml`, `element.yaml`) deploy onto it. Create it with `kind create cluster --name matrix-local --kubeconfig kubeconfig` if it doesn't exist.

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

Deleting the cluster permanently deletes its data (only `matrix-local` is affected):

```bash
kind delete cluster --name matrix-local
```
