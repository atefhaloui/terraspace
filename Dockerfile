FROM debian:bookworm-slim

# Args
ARG TERRAFORM_VERSION=1.13.3
ARG TERRASPACE_VERSION=2.2.18 # https://github.com/boltops-tools/terraspace/blob/master/CHANGELOG.md
ARG CHECKOV_VERSION=3.2.471
ARG TFLINT_VERSION=0.59.1
ARG TERRASPACE_USER=terraspace
ARG TERRASPACE_UID=1000
ARG TERRASPACE_GID=1000

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  wget \
  unzip \
  gnupg \
  git \
  file \
  jq \
  ca-certificates \
  ruby-full \
  build-essential \
  software-properties-common \
  python3 \
  python3-pip \
  python3-venv

# Install terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    TF_DEB_VERSION=$(apt-cache madison terraform | awk -v ver="$TERRAFORM_VERSION" -F'|' '$2 ~ ver {gsub(/ /,"",$2); print $2; exit}') && \
    apt-get -y install terraform=${TF_DEB_VERSION}

# Set environment for bundler
ENV BUNDLE_PATH=/opt/terraspace/vendor/bundle
ENV GEM_HOME=/opt/terraspace/vendor/bundle
ENV PATH="$GEM_HOME/bin:$PATH"

# Install terraspace + plugins globally in GEM_HOME
RUN gem install terraspace -v ${TERRASPACE_VERSION}
RUN gem install terraspace_plugin_aws \
    rspec-terraspace \
    terraspace_ci_gitlab \
    terraspace_vcs_gitlab \
    bundler

# Create terraspace user with UID/GID 1000
RUN groupadd -g ${TERRASPACE_GID} ${TERRASPACE_USER} && \
    useradd -m -u ${TERRASPACE_UID} -g ${TERRASPACE_USER} ${TERRASPACE_USER}

# Install awscliv2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
RUN curl -so "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
    unzip -q awscliv2.zip && \
    aws/install && \
    rm -rf awscliv2.zip aws && \
    aws --version

# Add AWS SDK in order to add more Ruby based scripts that can be used with the external terraform provider
RUN gem install aws-sdk

# Install Checkov (via pip)
RUN python3 -m venv /opt/checkov && \
    /opt/checkov/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/checkov/bin/pip install --no-cache-dir "checkov==${CHECKOV_VERSION}" && \
    ln -sf /opt/checkov/bin/checkov /usr/local/bin/checkov && \
    checkov --version

# Install TFLint (download binary from GitHub)
RUN ARCH="$(dpkg --print-architecture)"; \
  case "$ARCH" in \
    amd64) TFLINT_ARCH="amd64" ;; \
    arm64) TFLINT_ARCH="arm64" ;; \
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TFLINT_ARCH}.zip" && \
  unzip -q /tmp/tflint.zip -d /usr/local/bin && \
  chmod +x /usr/local/bin/tflint && \
  rm -f /tmp/tflint.zip && \
  tflint --version

# Cleanup
RUN rm -rf /var/lib/apt/lists/* /root/.cache/pip

# Switch to terraspace user
USER ${TERRASPACE_USER}

# ERROR: Terraspace requires Terraform between 0.12.x and 1.5.7
# This is because newer versions of Terraform have a BSL license
# If your usage is allowed by the license, you can bypass this check with:
#
#     export TS_VERSION_CHECK=0
#
# Note: If you're using Terraspace Cloud, you won't be able to bypass this check.
# See: https://terraspace.cloud/docs/terraform/license/
ENV TS_VERSION_CHECK=0
