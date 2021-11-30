#!/bin/bash

# File path for key material
FILEPATH=/home/pi/SSV-SDU-GUC-AGENT/guc/assets/key_material
set -e
# get current version
if [ $# -le 0 ]; then
	echo "Usage: $1 [version]"
	exit 1
fi

BASEURL=https://ssvdev-sdu0.ssv-service.de/v2
MAINTAINER=lko
VERSION=$1
PRODUCT=dummy
ASSIGNMENT_ID=41d94bb5-651d-4dd8-9673-cb3ed361ba77

PKIARGS="--cacert $FILEPATH/ssv-server-pki.crt.pem --cert $FILEPATH/$MAINTAINER.crt.pem --key $FILEPATH/$MAINTAINER.key.pem"

# Modify version assignment
curl -X PATCH \
	-H "Content-Type: application/json" \
	--data "{\"currentVersionAssignment\":{\"versionName\":\"$VERSION\",\"serialnumberFilter\":\"^000002112000001\"}}" \
	$PKIARGS \
	$BASEURL/product/$PRODUCT/currentVersionAssignment/$ASSIGNMENT_ID
