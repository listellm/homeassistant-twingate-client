# homeassistant-twingate-client

![Platform](https://img.shields.io/badge/platform-Home_Assistant_OS-41BDF5?logo=homeassistant&logoColor=white)
![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20aarch64-blue)
![License](https://img.shields.io/badge/license-MIT-green)
[![CI](https://github.com/listellm/homeassistant-twingate-client/actions/workflows/ci.yml/badge.svg)](https://github.com/listellm/homeassistant-twingate-client/actions/workflows/ci.yml)

Twingate headless client add-on for Home Assistant OS, enabling the host to access Twingate-protected resources via a Service Account.

## Prerequisites

Before installing this add-on, ensure you have:

- **Home Assistant OS** (HAOS) running on amd64 or aarch64 hardware
- A **Twingate account** with at least one Remote Network configured
- A **Twingate Connector** deployed in the Remote Network that hosts the resources you want to reach
- A **Twingate Service Account** with access granted to the desired Resources

If you do not yet have a Twingate account, sign up at [twingate.com](https://www.twingate.com) and follow their getting started guide to create a Remote Network and deploy a Connector.

## Getting Started

### Step 1: Create a Twingate Service Account

1. Open the **Twingate Admin Console**
2. Navigate to **Team > Service Accounts**
3. Click **Create Service Account** and give it a name (e.g. `home-assistant`)
4. Under **Resources**, grant it access to the Twingate Resources that HA needs to reach
5. Click **Generate Key** and copy the full JSON key. Keep this safe, you will need it in Step 3.

### Step 2: Install the add-on

Click the button below to add this repository to your Home Assistant instance:

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Flistellm%2Fhomeassistant-twingate-client)

Or manually:

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**
2. Click the three-dot menu (top right) and select **Repositories**
3. Paste the following URL and click **Add**:

   ```
   https://github.com/listellm/homeassistant-twingate-client
   ```

4. Close the dialog. The **Twingate Client** add-on should now appear in the store.
5. Click it and press **Install**. The image is built locally on your device from the Dockerfile. On a Raspberry Pi this can take 5-10 minutes on first install while it downloads the base image and Twingate packages. The spinner is normal; do not navigate away.

### Step 3: Configure and start

1. Go to the **Configuration** tab of the add-on
2. Paste the full JSON Service Account Key into the `service_key` field
3. Set `log_level` to `debug` for the first run (you can change this to `info` later)
4. Click **Save**, then click **Start**
5. Check the **Log** tab to confirm the Twingate client has connected successfully

### Step 4: Verify connectivity

Once the add-on is running, any other add-on or integration using host networking can reach your Twingate-protected resources. To verify:

1. Open the **Terminal & SSH** add-on (or any terminal with host network access)
2. Ping or curl the private IP of a Twingate Resource:

   ```bash
   ping <twingate-resource-ip>
   ```

3. If the ping succeeds, the tunnel is active and working

## Configuration

| Option        | Type   | Default | Description                                                      |
| ------------- | ------ | ------- | ---------------------------------------------------------------- |
| `service_key` | string | `""`    | Twingate Service Account Key (full JSON blob from admin console) |
| `log_level`   | enum   | `info`  | Log verbosity: `debug`, `info`, `warning`, `error`               |

## How it works

The add-on runs with `host_network: true` and `NET_ADMIN` privileges. On startup it:

1. Creates the `/dev/net/tun` device if it does not already exist
2. Writes the Service Account Key to `/etc/twingate/service_key.json`
3. Runs `twingate setup --headless` to configure the client
4. Starts the Twingate client in the foreground

Because the add-on shares the host network namespace, the Twingate tunnel is available to the entire HAOS host. Any other add-on running with `host_network: true` (such as OpenClaw, Node-RED, or Terminal & SSH) automatically inherits connectivity to Twingate-protected resources without additional configuration.

## Troubleshooting

**Add-on starts but cannot reach resources**

- Check the add-on logs for connection errors (set `log_level` to `debug`)
- Verify the Service Account has been granted access to the correct Resources in the Twingate Admin Console
- Ensure a Twingate Connector is deployed and online in the Remote Network hosting the target Resources

**Add-on fails to start**

- Confirm the `service_key` field contains the complete JSON key (not just the token string)
- Check that the key has not expired in the Twingate Admin Console

**Other add-ons cannot reach Twingate resources**

- The consuming add-on must use `host_network: true` in its own configuration to share the host network namespace where the Twingate tunnel is active

## Security

### Trivy scan results

Scanned on 2026-03-27 against `twingate-client-scan:latest` (base: `ghcr.io/home-assistant/amd64-base-debian:bookworm`, Twingate `2025.342.178568`).

| Severity | Count |
| -------- | ----- |
| CRITICAL | 3     |
| HIGH     | 10    |
| MEDIUM   | 43    |
| LOW      | 108   |

**CRITICAL findings**

| CVE            | Package                               | Installed       | Fixed                     |
| -------------- | ------------------------------------- | --------------- | ------------------------- |
| CVE-2023-45853 | zlib1g                                | 1:1.2.13.dfsg-1 | no fix in Debian bookworm |
| CVE-2024-45337 | golang.org/x/crypto (Twingate binary) | v0.26.0         | fixed in 0.31.0           |
| CVE-2025-68121 | stdlib (Twingate binary)              | v1.23.3         | fixed in 1.24.13 / 1.25.7 |

**HIGH findings (notable)**

| CVE                                       | Package                             | Notes                        |
| ----------------------------------------- | ----------------------------------- | ---------------------------- |
| CVE-2026-0861                             | libc-bin, libc6                     | no fix in Debian bookworm    |
| CVE-2023-2953                             | libldap-2.5-0                       | no fix in Debian bookworm    |
| CVE-2025-22869, CVE-2025-47907 and others | stdlib / x/crypto (Twingate binary) | upstream Twingate to resolve |

**Notes**

- OS-level findings with no fixed version are open Debian bookworm issues; they cannot be resolved by bumping package versions until Debian publishes updates.
- Findings in `stdlib` and `golang.org/x/crypto` are embedded inside the Twingate binary. These require Twingate to ship an updated release; the add-on will pick them up on the next Twingate package version bump.
- The badges above are static. Wire Trivy into the CI workflow to keep them current automatically.

To reproduce the scan:

```bash
docker build \
  --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm \
  -t twingate-client-scan:latest \
  ./twingate-client

trivy image --severity LOW,MEDIUM,HIGH,CRITICAL twingate-client-scan:latest
```

## Contributing

See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

[MIT](LICENSE)
