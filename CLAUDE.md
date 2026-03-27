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
  icon.png               # 128x128 add-on icon
  logo.png               # 256x256 add-on logo
  rootfs/
    etc/services.d/twingate-client/
      run                # s6-overlay service: writes service key, starts client
      finish             # s6-overlay service: cleanup on stop
```

## Key Design Decisions

- `host_network: true` so the Twingate tunnel is available to all host-networked containers
- `NET_ADMIN` privilege required for the TUN interface
- `/dev/net/tun` is created in the run script if missing (not all HAOS hosts expose it by default)
- Uses s6-overlay `services.d` structure (not `CMD`) as HA base images use s6-overlay as PID 1
- Service key is stored in add-on options and written to `/etc/twingate/service_key.json` at startup
- Base images are HA official Debian Bookworm (not Alpine, as Twingate requires glibc)
- Only amd64 and aarch64 supported (Twingate client does not publish armv7 packages)
- `hassio_api: true` for configuring hassio-dns with Twingate resolvers

## Hassio-DNS Integration

Twingate intercepts DNS for protected resources at the TUN interface level, returning
virtual IPs in the `100.96.0.0/12` range that route through the tunnel. However, other
HAOS add-on containers use hassio-dns (`172.30.32.3`) which forwards to upstream DNS
servers, bypassing Twingate's interception entirely. This means containers like OpenClaw
resolve Twingate-protected domains to their real (unreachable) private IPs.

The `configure_hassio_dns` option (default: true) fixes this by:

1. Detecting Twingate's internal DNS resolver IPs from `100.95.0.x` routes in the sdwan route table
2. Calling the Supervisor API to set them as hassio-dns upstream servers
3. Restoring the original DNS config when the add-on stops

Twingate's DNS resolvers handle both protected resources (returning virtual tunnel IPs) and
regular domains (forwarding to upstream). The hassio-dns `fallback: true` setting provides
Cloudflare DoT as a safety net if the Twingate resolvers become unreachable.

## Build and Test

The add-on is built by the HA Supervisor when installed. To test locally:

```bash
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm -t twingate-client ./twingate-client
```

## Dependencies

- Twingate APT repository: `packages.twingate.com`
- HA base images: `ghcr.io/home-assistant/{arch}-base-debian:bookworm`
