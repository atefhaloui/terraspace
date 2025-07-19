# Terraspace Dockerfiles

[![BoltOps Badge](https://img.boltops.com/boltops/badges/boltops-badge.png)](https://www.boltops.com)

This repo contains Dockerfiles that include [Terraspace](https://terraspace.cloud/). You can use it try out Terraspace within an isolated Docker container.

The Docker images are published to Dockerhub daily. The images generally include the latest version of Terraspace and Terraform.

For more docs, see: [Terraspace Docker Docs](https://terraspace.cloud/docs/install/docker/)

## Compilation

```
docker buildx build --network=host -t ghcr.io/boltops-tools .
docker tag terraspace docker.io/atefhaloui/terraspace:0.1.0
docker tag terraspace docker.io/atefhaloui/terraspace:latest
docker push docker.io/atefhaloui/terraspace:0.1.0
docker push docker.io/atefhaloui/terraspace:latest
```

## Usage

To run the terraspace docker container:
```
docker run --rm -ti terraspace
```