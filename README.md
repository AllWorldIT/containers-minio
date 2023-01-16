[![pipeline status](https://gitlab.conarx.tech/containers/minio/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/minio/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/minio) - [GitHub Mirror](https://github.com/AllWorldIT/containers-minio)

This is the Conarx Containers Minio image, it provides the Minio S3 server and Minio Client within the same Docker image.



# Mirrors

|  Provider  |  Repository                            |
|------------|----------------------------------------|
| DockerHub  | allworldit/minio                      |
| Conarx     | registry.conarx.tech/containers/minio |



# Commercial Support

Commercial support is available from [Conarx](https://conarx.tech).



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
