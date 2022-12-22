FROM registry.gitlab.iitsp.com/allworldit/docker/alpine:latest as builder

# Install libs we need
RUN set -ex; \
	true "Installing build dependencies"; \
# from https://git.alpinelinux.org/aports/tree/main/pdns/APKBUILD
	apk add --no-cache \
		build-base \
		\
		curl \
		go \
		git \
		jq

# Download packages
RUN set -ex; \
	mkdir -p build; \
	cd build; \
	# Lets get the latest minio release...
	MINIO_LATEST_TAG=$(curl -s https://api.github.com/repos/minio/minio/releases/latest | jq .tag_name | sed -e 's/"//g'); \
	MC_LATEST_TAG=$(curl -s https://api.github.com/repos/minio/mc/releases/latest | jq .tag_name | sed -e 's/"//g'); \
	# Do a quick sanity check to make s ure the latest tag contains "RELEASE"
	true "Checking minio tags contain 'RELEASE'"; \
	echo "$MINIO_LATEST_TAG" | grep -F 'RELEASE.'; \
	echo "$MC_LATEST_TAG" | grep -F 'RELEASE.'; \
	# Work out minio and mc versions
	MINIO_VERSION=0.$(echo "$MINIO_LATEST_TAG" | sed -e 's/RELEASE\.//; s/-//g; s/T/./; s/Z//'); \
	MC_VERSION=0.$(echo "$MC_LATEST_TAG" | sed -e 's/RELEASE\.//; s/-//g; s/T/./; s/Z//'); \
	# Output what we got
	echo "Minio latest: $MINIO_LATEST_TAG version $MINIO_VERSION"; \
	echo "Minio mc latest: $MC_LATEST_TAG version $MC_VERSION"; \
	# minio is a rolling release, so we need to checkout and check the latest tag
	git clone --branch "$MINIO_LATEST_TAG" --depth 1 https://github.com/minio/minio.git; \
	git clone --branch "$MC_LATEST_TAG" --depth 1 https://github.com/minio/mc.git; \
	# Save tag & info
	echo "MINIO_LATEST_TAG=$MINIO_LATEST_TAG" > verinfo; \
	echo "MC_LATEST_TAG=$MC_LATEST_TAG" >> verinfo; \
	echo "MINIO_VERSION=$MINIO_VERSION" >> verinfo; \
	echo "MC_VERSION=$MC_VERSION" >> verinfo


# Build and install Minio
RUN set -ex; \
	cd build; \
	source verinfo; \
	cd minio; \
	prefix='github.com/minio/minio/cmd'; \
	# Grab date and time stamps
	date=${MINIO_LATEST_TAG%%T*}; \
	time=${MINIO_LATEST_TAG#*T}; \
	# Build time!
	go build -tags kqueue -o bin/minio -ldflags " \
		-X $prefix.Version=${date}T${time//-/:} \
		-X $prefix.CopyrightYear=${date%%-*} \
		-X $prefix.ReleaseTag=$MINIO_LATEST_TAG \
		-X $prefix.CommitID=0000000000000000000000000000000000000000 \
		-X $prefix.ShortCommitID=000000000000 \
	"; \
	\
	install -Dm755 bin/minio -t /build/minio-root/usr/bin/

# Build and install Minio client
RUN set -ex; \
	cd build; \
	source verinfo; \
	cd mc; \
	prefix='github.com/minio/mc/cmd'; \
	# Grab date and time stamps
	date=${MC_LATEST_TAG%%T*}; \
	time=${MC_LATEST_TAG#*T}; \
	# Build time!
	go build -tags kqueue -o bin/mcli -ldflags " \
		-X $prefix.Version=${date}T${time//-/:} \
		-X $prefix.CopyrightYear=${date%%-*} \
		-X $prefix.ReleaseTag=$MC_LATEST_TAG \
		-X $prefix.CommitID=0000000000000000000000000000000000000000 \
		-X $prefix.ShortCommitID=000000000000 \
	"; \
	\
	install -Dm755 bin/mcli /build/minio-root/usr/bin/mc


RUN set -ex; \
	cd build/minio-root; \
	scanelf --recursive --nobanner --osabi --etype "ET_DYN,ET_EXEC" .  | awk '{print $3}' | xargs \
		strip \
			--remove-section=.comment \
			--remove-section=.note \
			-R .gnu.lto_* -R .gnu.debuglto_* \
			-N __gnu_lto_slim -N __gnu_lto_v1 \
			--strip-unneeded



FROM registry.gitlab.iitsp.com/allworldit/docker/alpine:latest

ARG VERSION_INFO=
LABEL maintainer="Nigel Kukard <nkukard@lbsd.net>"


# Copy in built binaries
COPY --from=builder /build/minio-root /


RUN set -ex; \
	true "Utilities"; \
	apk add --no-cache \
		curl; \
	true "User setup"; \
	addgroup -S minio 2>/dev/null; \
	adduser -S -D -H -h /var/lib/minio -s /sbin/nologin -G minio -g minio minio; \
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*


# Minio
COPY etc/supervisor/conf.d/minio.conf /etc/supervisor/conf.d/minio.conf
COPY pre-init-tests.d/60-minio.sh /docker-entrypoint-pre-init-tests.d/60-minio.sh
COPY init.d/60-minio.sh /docker-entrypoint-init.d/60-minio.sh
COPY tests.d/60-minio.sh /docker-entrypoint-tests.d/60-minio.sh
COPY usr/bin/start-minio /usr/bin/start-minio
RUN set -ex; \
	mkdir /etc/minio; \
	chown root:root \
		/docker-entrypoint-init.d/60-minio.sh \
		/docker-entrypoint-pre-init-tests.d/60-minio.sh \
		/docker-entrypoint-tests.d/60-minio.sh \
		/usr/bin/start-minio; \
	chmod 0755 \
		/docker-entrypoint-init.d/60-minio.sh \
		/docker-entrypoint-pre-init-tests.d/60-minio.sh \
		/docker-entrypoint-tests.d/60-minio.sh \
		/usr/bin/start-minio

VOLUME ["/var/lib/minio"]

EXPOSE 9000:9001

HEALTHCHECK CMD curl --silent --fail http://localhost:9000/minio/health/live

