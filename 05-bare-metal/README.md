# 5 — Bare metal: native Tuwunel (systemd, no Docker)

`install-tuwunel.sh` works on an **old PC** and a **dedicated server**. It supports Debian/Ubuntu on x86_64 or arm64, installs the Tuwunel release binary as a systemd service, writes a random registration token to `/root/tuwunel-registration-token`, and enables a `ufw` firewall.

Plain HTTP: use disposable accounts only.

## Prerequisites: the OS comes first

A bare machine has no OS, so the script can't run until you install one. It needs:

1. **Debian 12 or Ubuntu 24.04 Server** (x86_64 or arm64, no desktop). It provides bash, systemd and apt; the script refuses to run without apt or root. Install from a USB stick on an old PC, or with `installimage` in Hetzner Rescue on a dedicated server.
2. **Network and SSH access** with a fixed IP (or DHCP reservation), so you can copy the script over from your laptop.
3. **Root** (directly or via `sudo`).

The script installs the rest itself (`curl`, `zstd`, `ufw`, `iproute2`, the Tuwunel binary).

### Tools on your laptop

You only need `ssh` and `scp` (preinstalled on macOS/Linux; Windows 10+ has OpenSSH) and a way to write a USB stick:

```bash
brew install --cask balenaetcher    # or Raspberry Pi Imager: brew install --cask raspberry-pi-imager
ssh-keygen -t ed25519               # if you have no SSH key yet
```

For the Hetzner VM variant you also need Terraform (see scenario 4).

### Step 0 (old PC): install the OS yourself

Nothing is pre-installed, and installing the OS wipes the disk. Back up first.

1. On your laptop, download the **Ubuntu Server 24.04 LTS** ISO (or Debian 12 netinst) and verify its checksum.
2. Write it to a USB stick (8 GB+) with balenaEtcher, Raspberry Pi Imager or `dd`. Double-check the target disk.
3. Plug the stick into the PC, power on, and open the boot menu (usually F12, F10, Esc or Del). Boot from USB. If it won't boot, check that Secure Boot allows it, or disable it.
4. Run the installer:
   - Choose the minimal server install, with no desktop.
   - Wired network is best. Note the IP it gets, or reserve one in your router.
   - Use the whole disk, or manual partitioning if you want a specific layout.
   - Create a user and enable **Install OpenSSH server** (add your public key if offered).
   - Skip all optional snaps/packages.
5. Reboot, remove the USB stick, and from your laptop check `ssh <user>@<pc-ip>`.

Then continue with the old-PC steps below.

On a Hetzner dedicated server there is no USB stick: the equivalent is Rescue + `installimage` (see the dedicated-server section below).

## Old PC (LAN)

1. Install Debian or Ubuntu Server (no desktop) and enable SSH. Give the PC a fixed address or DHCP reservation, because the server name is its IP.
2. Copy and run the script as root:

   ```bash
   scp install-tuwunel.sh <user>@<pc-ip>:
   ssh <user>@<pc-ip> 'sudo bash install-tuwunel.sh'
   ```

   With a private address it uses that IP as the server name and allows SSH and port 8008 only from the local subnet.
3. Read the token: `sudo cat /root/tuwunel-registration-token`, then use `http://<pc-ip>:8008` as the custom homeserver from another LAN device. Changing the IP later changes the server name, so create a new account.

If the PC has a public IP or your client is in another subnet, pass `CLIENT_CIDR=<your-ip>/32` (required for public addresses). A wrong value can lock out SSH.

## What is running now: a second Hetzner VM

No spare PC, so this demo runs the same native install on a Hetzner VM defined in [`../04-hetzner-terraform/native.tf`](../04-hetzner-terraform/native.tf) (`cloud-init-native.yaml.tftpl`). Server `http://178.105.190.29:8008`.

```bash
terraform -chdir=04-hetzner-terraform output -raw native_homeserver_url
terraform -chdir=04-hetzner-terraform output -raw native_registration_token
```

## Hetzner dedicated server (literal bare metal) — not ordered

Ordered via Hetzner Robot (not Terraform), billed monthly. Cheapest seen: AX41-1-LTD, €59/month before VAT, no setup fee. Needs explicit budget approval.

1. In Robot, add your SSH public key, order, wait for the provisioning email.
2. Server → **Rescue** → activate Linux with your key → **Reset** → automatic hardware reset. `ssh root@<server-ip>`.
3. Run `installimage`, choose Ubuntu 24.04, keep or adjust RAID 1, save, `reboot`, reconnect (host key changes).
4. Run the script, allowing only your client IP:

   ```bash
   scp install-tuwunel.sh root@<server-ip>:
   ssh root@<server-ip> 'CLIENT_CIDR=<your-ip>/32 bash install-tuwunel.sh'
   ```

   Dedicated servers have no Hetzner Cloud Firewall, so the host `ufw` firewall is essential.
5. Check `curl http://<server-ip>:8008/_matrix/client/versions` and use that URL in Element.

If your public IP changes, SSH is blocked; use Rescue to reconnect. Cancel the server in Robot when done.
