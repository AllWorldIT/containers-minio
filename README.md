# Introduction

This is a Minio container.

See the [Alpine Base Image](https://gitlab.iitsp.com/allworldit/docker/alpine) project for additional configuration.

# Minio

All environment variables beginning with `MINIO_` are passed to `minio`.

## Volume: /var/lib/minio

Data directory.

## Ports: 9000

Exposes Minio port 9000.

## MINIO_OPTS

Options passed to `minio server`, defaults to `/var/lib/minio`.

## MINIO_ROOT_USER

Username to use.

## MINIO_ROOT_PASSWORD

Password to use for for the root user.


