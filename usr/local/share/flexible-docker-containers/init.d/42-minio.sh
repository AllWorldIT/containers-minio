#!/bin/bash
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


fdc_notice "Setting up Minio permissions"
# Make sure our data directory perms are correct
chown root:minio /var/lib/minio
chmod 0770 /var/lib/minio
# Set permissions on Minio configuration
chown root:minio /etc/minio
chmod 0750 /etc/minio


fdc_notice "Initializing Minio settings"

if [ -z "$MINIO_ROOT_USER" ]; then
	fdc_warn "Environment variable 'MINIO_ROOT_USER' not set, minio will use defaults!"
	export MINIO_ROOT_USER=minioadmin
fi

if [ -z "$MINIO_ROOT_PASSWORD" ]; then
	fdc_warn "Environment variable 'MINIO_ROOT_PASSWORD' not set, minio will use defaults!"
	export MINIO_ROOT_PASSWORD=minioadmin
fi

# To make admin easy, we're going to load the credentials into the mc config file
mkdir /root/.mc
cat <<EOF > /root/.mc/config.json
{
	"version": "10",
	"aliases": {
		"s3": {
			"url": "http://localhost:9000",
			"accessKey": "$MINIO_ROOT_USER",
			"secretKey": "$MINIO_ROOT_PASSWORD",
			"api": "s3v4",
			"path": "auto"
		}
	}
}
EOF


# Write out environment and fix perms of the config file
set | grep -E '^MINIO_' > /etc/minio/minio.conf || true
chown root:minio /etc/minio/minio.conf
chmod 0640 /etc/minio/minio.conf
