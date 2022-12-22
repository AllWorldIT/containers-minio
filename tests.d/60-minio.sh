#!/bin/sh


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

	curl -X PUT -T "${srcfile}" \
        -H "Host: ${host}" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${s3_key}:${signature}" \
        "http://${host}:9000${resource}"
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

	curl -o "$target" \
        -H "Host: ${host}" \
        -H "Date: ${date}" \
        -H "Content-Type: ${content_type}" \
        -H "Authorization: AWS ${s3_key}:${signature}" \
        http://${host}:9000${resource}
}


if ! curl -f http://localhost:9000/minio/health/live; then
	echo "CHECK FAILED (minio): Healthcheck failed"
	false
fi

#
# Try upload and download
#

# Setup mc
mc alias set minioserver http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
# Create bucket
mc mb minioserver/citest

# Upload file
echo PASSED > /tmp/file.txt
uploadfile "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" citest / /tmp/file.txt

# Test file is restricted by default
TEST_OUTPUT=$(wget -O- http://localhost:9000/citest/file.txt 2>&1 || true)
if ! echo "$TEST_OUTPUT" | grep Forbidden; then
	echo "CHECK FAILED (minio): Should return 'Forbidden' trying to access content"
	false
fi

# Grab file contents...
getfile "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" citest file.txt /tmp/file.txt.test
if ! diff /tmp/file.txt /tmp/file.txt.test; then
	echo "CHECK FAILED (minio): Downloaded file does not match uploaded one"
	false
fi



echo "CHECK (minio): PASSED"