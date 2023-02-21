# Copyright (c) 2022-2023, AllWorldIT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


FROM registry.conarx.tech/containers/alpine/edge as builder


# Install libs we need
RUN set -eux; \
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
RUN set -eux; \
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
	echo "MINIO_LATEST_TAG=$MINIO_LATEST_TAG" > VERSIONS.env; \
	echo "MC_LATEST_TAG=$MC_LATEST_TAG" >> VERSIONS.env; \
	echo "MINIO_VERSION=$MINIO_VERSION" >> VERSIONS.env; \
	echo "MC_VERSION=$MC_VERSION" >> VERSIONS.env


# Build and install Minio
RUN set -eux; \
	cd build; \
	source VERSIONS.env; \
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
RUN set -eux; \
	cd build; \
	source VERSIONS.env; \
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


RUN set -eux; \
	cd build/minio-root; \
	scanelf --recursive --nobanner --osabi --etype "ET_DYN,ET_EXEC" .  | awk '{print $3}' | xargs \
		strip \
			--remove-section=.comment \
			--remove-section=.note \
			-R .gnu.lto_* -R .gnu.debuglto_* \
			-N __gnu_lto_slim -N __gnu_lto_v1 \
			--strip-unneeded



FROM registry.conarx.tech/containers/alpine/edge


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   = "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   = "edge"
LABEL org.opencontainers.image.base.name = "registry.conarx.tech/containers/alpine/edge"


# Copy in built binaries
COPY --from=builder /build/minio-root /


RUN set -eux; \
	true "Utilities"; \
	apk add --no-cache \
		curl \
		openssl; \
	true "User setup"; \
	addgroup -S minio 2>/dev/null; \
	adduser -S -D -H -h /var/lib/minio -s /sbin/nologin -G minio -g minio minio; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*


# Minio
COPY etc/supervisor/conf.d/minio.conf /etc/supervisor/conf.d/minio.conf
COPY usr/local/share/flexible-docker-containers/healthcheck.d/42-minio.sh /usr/local/share/flexible-docker-containers/healthcheck.d
COPY usr/local/share/flexible-docker-containers/init.d/42-minio.sh /usr/local/share/flexible-docker-containers/init.d
COPY usr/local/share/flexible-docker-containers/pre-init-tests.d/42-minio.sh /usr/local/share/flexible-docker-containers/pre-init-tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/42-minio.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/bin/start-minio /usr/bin/start-minio
RUN set -eux; \
	true "Flexible Docker Containers"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	mkdir /etc/minio; \
	chown root:root \
		/usr/bin/start-minio; \
	chmod 0755 \
		/usr/bin/start-minio; \
	fdc set-perms

VOLUME ["/var/lib/minio"]

EXPOSE 9000:9001
