FROM debian:bookworm-slim

# Args
ARG TERRAFORM_VERSION=1.12.2-1
ARG TERRASPACE_VERSION=2.2.17
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
  ca-certificates \
  ruby-full \
  build-essential \
  software-properties-common

# Install terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get -y install terraform=${TERRAFORM_VERSION}

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

ENV TS_BUNDLER=0

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

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

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