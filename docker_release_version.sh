#!/bin/sh
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


set -e

apk add --no-cache curl jq

# Lets get the latest minio release...
MINIO_LATEST_TAG=$(curl -s https://api.github.com/repos/minio/minio/releases/latest | jq .tag_name | sed -e 's/"//g')
# Do a quick sanity check to make s ure the latest tag contains "RELEASE"
echo "$MINIO_LATEST_TAG" | grep -qF 'RELEASE.'
# Work out minio and mc versions
MINIO_VERSION=0.$(echo "$MINIO_LATEST_TAG" | sed -e 's/RELEASE\.//; s/-//g; s/T/./; s/Z//'); \

export CONTAINER_VERSION_EXTRA="$MINIO_VERSION"