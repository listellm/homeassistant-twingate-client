ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        ca-certificates \
    && curl -fsSL https://packages.twingate.com/apt/gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/twingate-client-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/twingate-client-keyring.gpg] https://packages.twingate.com/apt/ * *" \
        > /etc/apt/sources.list.d/twingate.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends twingate \
    && apt-get purge -y --auto-remove gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/twingate

COPY rootfs /
