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


function uploadfile() {
	host=localhost
	s3_key=$1
	s3_secret=$2
	bucket=$3
	path=$4
	srcfile=$5

	dstfilename=$(basename "$srcfile")
	dstfile="${path}${dstfilename}"

	resource="/${bucket}${dstfile}"
	content_type="application/octet-stream"
	date=`date -R`
	_signature="PUT\n\n${content_type}\n${date}\n${resource}"
	signature=`echo -en ${_signature} | openssl dgst -sha1 -hmac ${s3_secret} -binary | base64`

	if ! curl -X PUT -T "${srcfile}" \
        -H "Host: ${host}" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${s3_key}:${signature}" \
        "http://${host}:9000${resource}"
	then
		return 1
	fi
	return
}


function getfile() {
	host=localhost
	s3_key=$1
	s3_secret=$2
	bucket=$3
	file=$4
	target=$5

	resource="/${bucket}/${file}"
	content_type="application/octet-stream"
	date=`date -R`
	_signature="GET\n\n${content_type}\n${date}\n${resource}"
	signature=`echo -en ${_signature} | openssl dgst -sha1 -hmac ${s3_secret} -binary | base64`

	if ! curl -o "$target" \
        -H "Host: ${host}" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${s3_key}:${signature}" \
        http://${host}:9000${resource}
	then
		return 1
	fi
	return
}



echo "TEST START (minio): Checking minio responds"
if ! curl -f http://localhost:9000/minio/health/live; then
	echo "TEST FAILED (minio): Minio not responding"
	false
fi
echo "TEST PASSED (minio): Minio responding, continuing with tests"



#
# Try upload and download
#

# Create bucket
echo "TEST START (minio): Creating bucket"
if ! mc mb s3/citest; then
	echo "TEST FAILED (minio): Bucket create failed"
	false
fi
echo "TEST PASSED (minio): Bucket created"


# Upload file
echo PASSED > /tmp/file.txt
echo "TEST START (minio): Upload file"
if ! uploadfile "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" citest / /tmp/file.txt; then
	echo "TEST FAILED (minio): Uploading file failed"
	false
fi
echo "TEST PASSED (minio): File uploaded"


# Test file is restricted by default
echo "TEST START (minio): Download file returns forbidden on private file"
TEST_OUTPUT=$(wget -O- http://localhost:9000/citest/file.txt 2>&1 || true)
if ! echo "$TEST_OUTPUT" | grep Forbidden; then
	echo "CHECK FAILED (minio): Did not return 'Forbidden' downloading private file"
	false
fi
echo "TEST PASSED (minio): Downloaded correctly returned 'Forbidden' on private file"


# Grab file contents...
echo "TEST START (minio): Download file returns correct content"
getfile "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" citest file.txt /tmp/file.txt.test
if ! diff /tmp/file.txt /tmp/file.txt.test; then
	echo "CHECK FAILED (minio): Downloaded file does not match uploaded one"
	false
fi
echo "TEST PASSED (minio): Downloaded file returned correct contents"
