# Sandbox image for agent-deck sessions. Build with B in agent-deck-menu.
# Based on agent-deck v1.16.26 sandbox/Dockerfile, without OpenCode and Gemini.

FROM ubuntu:24.04

ARG HOST_HOME
ARG HOST_UID=501
ARG HOST_GID=20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bubblewrap \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    git \
    git-lfs \
    gnupg \
    jq \
    openssh-client \
    python3 \
    python3-pip \
    ripgrep \
    socat \
    unzip \
    uuid-runtime \
    vim-tiny \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN git lfs install

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com noble main" \
      > /etc/apt/sources.list.d/hashicorp.list \
  && apt-get update && apt-get install -y --no-install-recommends gh terraform \
  && rm -rf /var/lib/apt/lists/*

# dpkg reports the build platform even with the legacy builder, where
# TARGETARCH is empty.
RUN case "$(dpkg --print-architecture)" in \
      arm64) arch=aarch64 ;; \
      amd64) arch=x86_64 ;; \
      *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac \
  && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o /tmp/awscliv2.zip \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install \
  && rm -rf /tmp/aws /tmp/awscliv2.zip

ARG AWS_VAULT_VERSION=v7.17.7
RUN arch="$(dpkg --print-architecture)" \
  && base="https://github.com/ByteNess/aws-vault/releases/download/${AWS_VAULT_VERSION}" \
  && curl -fsSL "${base}/aws-vault-linux-${arch}" -o "/tmp/aws-vault-linux-${arch}" \
  && curl -fsSL "${base}/aws-vault_sha256_checksums.txt" -o /tmp/aws-vault.sha256 \
  && (cd /tmp && grep " aws-vault-linux-${arch}\$" aws-vault.sha256 | sha256sum -c -) \
  && install -m 0755 "/tmp/aws-vault-linux-${arch}" /usr/local/bin/aws-vault \
  && rm -f "/tmp/aws-vault-linux-${arch}" /tmp/aws-vault.sha256

WORKDIR /root

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1

RUN npm install -g @openai/codex@latest

# installed_plugins.json holds host paths such as
# $HOST_HOME/.claude/plugins/cache/..., so point them at the mount.
RUN test -n "$HOST_HOME" || { echo "set --build-arg HOST_HOME" >&2; exit 1; }; \
    mkdir -p /root/.claude /root/.codex /root/.ssh /root/.aws "$HOST_HOME" \
  && ln -s /root/.claude "$HOST_HOME/.claude"

# Per-container Codex plugin state, because every container uses /workspace.
RUN mkdir -p /root/.claude/plugins/data \
  && chown "$HOST_UID:$HOST_GID" /root/.claude/plugins/data \
  && chmod 700 /root/.claude/plugins/data
VOLUME ["/root/.claude/plugins/data"]

RUN chmod 755 /root

ENV IS_SANDBOX=1
# Writable mount. CODEX_HOME avoids the host auth.json copy in /root/.codex.
ENV GH_CONFIG_DIR=/root/.claude/gh
ENV CODEX_HOME=/root/.claude/codex
# Linux has no Keychain, and seccomp.json blocks keyctl. The empty passphrase
# lets agents run aws-vault unattended. Device code avoids the 127.0.0.1 callback.
ENV AWS_CONFIG_FILE=/root/.aws/config
ENV AWS_VAULT_BACKEND=file
ENV AWS_VAULT_FILE_DIR=/root/.aws/keys
ENV AWS_VAULT_FILE_PASSPHRASE=""
ENV AWS_VAULT_DEVICE_CODE=true

WORKDIR /workspace

CMD ["sleep", "infinity"]
