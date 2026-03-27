# CLAUDE.md

## Repository Purpose

Home Assistant add-on that runs the Twingate headless client on the HAOS host network, allowing other add-ons and integrations to reach Twingate-protected resources via a Service Account.

## Architecture

This is a standard Home Assistant add-on repository:

```
repository.yaml          # HA add-on store metadata
twingate-client/
  config.yaml            # Add-on definition (options, privileges, arch)
  build.yaml             # Maps architectures to HA base images
  Dockerfile             # Installs Twingate from official APT repo
  run.sh                 # Entrypoint: writes service key, starts client
```

## Key Design Decisions

- `host_network: true` so the Twingate tunnel is available to all host-networked containers
- `NET_ADMIN` privilege required for the TUN interface
- `/dev/net/tun` is created in `run.sh` if missing (not all HAOS hosts expose it by default)
- Service key is stored in add-on options and written to `/etc/twingate/service_key.json` at startup
- Base images are HA official Debian Bookworm (not Alpine, as Twingate requires glibc)
- Only amd64 and aarch64 supported (Twingate client does not publish armv7 packages)

## Build and Test

The add-on is built by the HA Supervisor when installed. No CI pipeline exists yet. To test locally:

```bash
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm -t twingate-client ./twingate-client
```

## Dependencies

- Twingate APT repository: `packages.twingate.com`
- HA base images: `ghcr.io/home-assistant/{arch}-base-debian:bookworm`
