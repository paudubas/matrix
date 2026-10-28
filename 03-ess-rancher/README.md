# 3 — Helm: ESS Community on Rancher Desktop

After creating an account below, sign in at **https://chat.ess.localhost** with
the username and password you chose (`@admin:ess.localhost` if you create the
admin as `admin`).

ESS Community 26.10.3 runs in namespace `ess` on Rancher Desktop v1.24.0 (Kubernetes v1.34.3; v1.21.0 could not start it). Login redirects to `https://account.ess.localhost` (Matrix Authentication Service). Federation is not configured. ESS is for non-commercial community use; see the [official chart](https://github.com/element-hq/ess-helm).

## Install first

You need a local Kubernetes cluster, `kubectl` and `helm`. Rancher Desktop provides the cluster (k3s with the Traefik ingress this guide uses).

```bash
brew install --cask rancher    # macOS; Linux/Windows: https://rancherdesktop.io
brew install kubectl helm      # Rancher Desktop also bundles them in ~/.rd/bin
```

1. Open Rancher Desktop **Preferences → Kubernetes → Ingress**. Choose **dockerd (moby)** or containerd, set Kubernetes to **v1.34.3 or newer**, and make sure **Enable Traefik** is checked. ESS uses Traefik to serve its local web addresses.
2. Give it about 4 CPUs and 8 GB RAM, and wait until it reports Kubernetes is running.
3. Verify: `kubectl --context rancher-desktop get nodes` and `helm version`.

`openssl` (for the certificate below) is preinstalled on macOS and most Linux. Trusting the certificate with `security` is macOS-only; on Linux add it to your system or browser trust store.

## Operate

Always pass the context explicitly:

```bash
kubectl --context rancher-desktop -n ess get pods,ingress
```

## Install

Values: `hostnames.yaml` and `local-http.yaml` (never use the HTTP-only values publicly). Run from this folder.

```bash
helm upgrade --install ess \
  oci://ghcr.io/element-hq/ess-helm/matrix-stack \
  --kube-context rancher-desktop --namespace ess --create-namespace \
  -f hostnames.yaml -f local-http.yaml \
  --wait --timeout 15m
```

## Create the admin account

After the chart is installed, run the interactive registration command. Enter
`admin` as the username, choose a password when prompted, and keep it for
Element sign-in. The `--admin` flag grants this user admin privileges; this
does not set a default password.

```bash
kubectl --context rancher-desktop exec -n ess -it \
  deploy/ess-matrix-authentication-service -- mas-cli manage register-user --admin
```

## Local TLS certificate

The chart always advertises `https://` URLs, so the browser must trust a certificate for every `*.ess.localhost` host. A self-signed one (`tls/`, git-ignored) replaces Traefik's default:

```bash
mkdir -p 03-ess-rancher/tls && cd 03-ess-rancher/tls    # from the repo root
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
  -keyout ess.key -out ess.crt -subj "/CN=ess.localhost" \
  -addext "subjectAltName=DNS:*.ess.localhost,DNS:ess.localhost" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "extendedKeyUsage=serverAuth"
kubectl --context rancher-desktop -n kube-system create secret tls ess-local-tls --cert=ess.crt --key=ess.key
kubectl --context rancher-desktop apply -f - <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: TLSStore
metadata: {name: default, namespace: kube-system}
spec: {defaultCertificate: {secretName: ess-local-tls}}
YAML
security add-trusted-cert -r trustRoot -k ~/Library/Keychains/login.keychain-db ess.crt
```

Remove trust later: `security delete-certificate -c ess.localhost`. Firefox uses its own store, so accept the certificate there. Restart the browser after trusting.

Rancher Desktop forwards host port 443 to Traefik. Port 80 is used by another local app, which doesn't affect the HTTPS URL.

## Cleanup

Uninstall the ESS release and remove its namespace. Deleting the namespace
permanently deletes ESS accounts, messages and other namespaced data:

```bash
helm uninstall ess --kube-context rancher-desktop --namespace ess
kubectl --context rancher-desktop delete namespace ess
```

If you created the local TLS certificate above, remove the trust entry and
Rancher Desktop TLS resources as well. On Linux, remove the certificate from
the system/browser trust store where you added it. This only removes the
certificate created for this guide; check first if you changed the shared
default TLS store for another local app.

```bash
# macOS only
security delete-certificate -c ess.localhost
kubectl --context rancher-desktop delete tlsstore default -n kube-system
kubectl --context rancher-desktop delete secret ess-local-tls -n kube-system
rm -f tls/ess.crt tls/ess.key
```
