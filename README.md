[![pipeline status](https://gitlab.conarx.tech/containers/minio/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/minio/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/minio) - [GitHub Mirror](https://github.com/AllWorldIT/containers-minio)

This is the Conarx Containers Minio image, it provides the Minio S3 server and Minio Client within the same Docker image.



# Mirrors

|  Provider  |  Repository                           |
|------------|---------------------------------------|
| DockerHub  | allworldit/minio                      |
| Conarx     | registry.conarx.tech/containers/minio |



# Conarx Containers

All our Docker images are part of our Conarx Containers product line. Images are generally based on Alpine Linux and track the
Alpine Linux major and minor version in the format of `vXX.YY`.

Images built from source track both the Alpine Linux major and minor versions in addition to the main software component being
built in the format of `vXX.YY-AA.BB`, where `AA.BB` is the main software component version.

Our images are built using our Flexible Docker Containers framework which includes the below features...

- Flexible container initialization and startup
- Integrated unit testing
- Advanced multi-service health checks
- Native IPv6 support for all containers
- Debugging options



# Community Support

Please use the project [Issue Tracker](https://gitlab.conarx.tech/containers/minio/-/issues).



# Commercial Support

Commercial support for all our Docker images is available from [Conarx](https://conarx.tech).

We also provide consulting services to create and maintain Docker images to meet your exact needs.



# Environment Variables

Additional environment variables are available from...
* [Conarx Containers Alpine image](https://gitlab.conarx.tech/containers/alpine).


## MINIO_OPTS

Options passed to `minio server`, defaults to `/var/lib/minio`.


## MINIO_ROOT_USER

Username to use, this will default to `minioadmin` if not specified which is terribly insecure.


## MINIO_ROOT_PASSWORD

Password to use for for the root user, this will default to `minioadmin` if not specified which is terribly insecure.


## MINIO_*

All other environment variables beginning with `MINIO_` will be passed to Minio.



# Volumes


## /var/lib/minio

Minio data directory. This should be on an XFS filesystem as recommended in the Minio documentation.



# Exposed Ports

Minio port 9000 and 9001 is exposed.



# Administration

The `s3` mc alias is setup automatically.

The Minio admin command can be executed from the host using...

```
docker-compose exec minio mc ls s3\mybucket
```


# Configuration Exampmle


```yaml
version: '3.9'

services:
  minio:
    image: registry.gitlab.iitsp.com/allworldit/docker/minio/v3.17:latest
    environment:
      - MINIO_BROWSER_REDIRECT_URL=https://console.s3.countrya-1.example.com
      - MINIO_ROOT_USER=xxxxx
      - MINIO_ROOT_PASSWORD=aaaaa
    volumes:
      - ./data:/var/lib/minio
    ports:
      - '9000:9000'
      - '9001:9001'
    extra_hosts:
      - "s3.countrya-1.example.com:172.16.0.1"
    networks:
      - internal

networks:
  internal:
    driver: bridge
    enable_ipv6: true
```