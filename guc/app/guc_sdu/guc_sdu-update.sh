#!/usr/bin/env bash

# Some notes on error handling:
# These options ensure that the script exits if one SIMPLE command returns
# a non-zero return code. SIMPLE commands are:
# - lines without "local"
# - lines without "&&", "||", "while", "until", "!" (and maybe more?)
set -eo pipefail
shopt -s inherit_errexit
FILEPATH=/home/pi
log () {
	echo ":$1" >&2
}

err () {
	echo $1 >&2
	exit 1
}
# Set environment
chmod +x $FILEPATH/sdu_guc_ssv/clients/guc_sdu-update_environment.sh
. $FILEPATH/sdu_guc_ssv/clients/guc_sdu-update_environment.sh

# Check for environment variables
[ -z "$SDU_SERVER_URL" ] && err "Environment SDU_SERVER_URL not set"
[ -z "$SDU_SERVER_CA" ] && err "Environment SDU_SERVER_CA not set"
[ ! -f "$SDU_SERVER_CA" ] && err "File SDU_SERVER_CA not found"
[ -z "$SDU_SERVER_CLIENT_CRT" ] && err "Environment SDU_SERVER_CLIENT_CRT not set"
[ ! -f "$SDU_SERVER_CLIENT_CRT" ] && err "File SDU_SERVER_CLIENT_CRT not found"
[ -z "$SDU_SERVER_CLIENT_KEY" ] && err "Environment SDU_SERVER_CLIENT_KEY not set"
[ ! -f "$SDU_SERVER_CLIENT_KEY" ] && err "File SDU_SERVER_CLIENT_KEY not found"
[ -z "$SDU_MAINTENANCE_CA" ] && err "Environment SDU_MAINTENANCE_CA not set"
[ ! -f "$SDU_MAINTENANCE_CA" ] && err "File SDU_MAINTENANCE_CA not found"

api_fetch () {
	local URL="$SDU_SERVER_URL/v2/$1"
	local HEADER_FILE="$2"

	local ARGS="-X GET --fail --silent --show-error \
		--cacert $SDU_SERVER_CA --cert $SDU_SERVER_CLIENT_CRT --key $SDU_SERVER_CLIENT_KEY"

	if [ -n "$HEADER_FILE" ]; then
		ARGS="$ARGS --dump-header $HEADER_FILE"
	fi

	log "    GET $URL"
	curl $ARGS $URL
}

api_fetch_status_code () {
	local URL="$SDU_SERVER_URL/v2/$1"
	local HEADER_FILE="$2"

	local ARGS="--head --silent --output /dev/null --write-out %{http_code} \
		--cacert $SDU_SERVER_CA --cert $SDU_SERVER_CLIENT_CRT --key $SDU_SERVER_CLIENT_KEY"

	if [ -n "$HEADER_FILE" ]; then
		ARGS="$ARGS --dump-header $HEADER_FILE"
	fi

	log "    HEAD $URL"
	curl $ARGS $URL || true
}

api_fetch_current_version () {
	local PRODUCT=$1
	api_fetch product/$PRODUCT/currentVersion | jq -r '.currentVersion.name'
}

api_fetch_blob_sha256 () {
	local PRODUCT=$1
	local VERSION=$2
	local HEADER_FILE=$(mktemp)
	trap 'rm -f $HEADER_FILE' RETURN

	# Download the manifest
	local MANIFEST SIGN_TIMESTAMP MANIFEST_BODY
	MANIFEST=$(api_fetch product/$PRODUCT/version/$VERSION/manifest $HEADER_FILE)
	SIGN_TIMESTAMP=$(grep 'X-Upload-Date' $HEADER_FILE | sed 's/.*: \([0-9]*\)\r/\1/')
	MANIFEST_BODY=$(echo "$MANIFEST" | openssl cms -attime $SIGN_TIMESTAMP -verify -CAfile $SDU_MAINTENANCE_CA)

	# Check manifest info
	local MANIFEST_PRODUCT MANIFEST_VERSION
	MANIFEST_PRODUCT=$(echo "$MANIFEST_BODY" | jq -r .product)
	if [ "$MANIFEST_PRODUCT" != "$PRODUCT" ]; then
		echo "Manifest product and desired product don't match" >&2
		return 101
	fi;
	MANIFEST_VERSION=$(echo "$MANIFEST_BODY" | jq -r .version)
	if [ "$MANIFEST_VERSION" != "$VERSION" ]; then
		echo "Manifest version and desired version don't match" >&2
		return 102
	fi

	# Extract SHA256
	echo "$MANIFEST_BODY" | jq -r .sha256
}

ZEROFILE_PATH=$(mktemp)
trap 'rm -f $ZEROFILE_PATH' EXIT
ZEROFILE_SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
api_fetch_blob () {
	local SHA256=$1
	local KNOWN_SHA256=$2
	local KNOWN_PATH=$3

	if [ -z "$KNOWN_SHA256" -o "$KNOWN_SHA256" = "null" ] || [ $(api_fetch_status_code blob/$SHA256/xdeltadiff/$KNOWN_SHA256) -ge "400" ]; then
		api_fetch blob/$SHA256/xdeltadiff/$ZEROFILE_SHA256 | xdelta3 -d -c -s $ZEROFILE_PATH
	else
		api_fetch blob/$SHA256/xdeltadiff/$KNOWN_SHA256 | xdelta3 -d -c -s $KNOWN_PATH
	fi
}

trigger_update () {
	local AGENT=$1

	local AGENT_INFO
	AGENT_INFO=$($AGENT info)

	# Check if update should be performed
	local PRODUCT INSTALLED_VERSION LATEST_VERSION
	PRODUCT=$(echo $AGENT_INFO | jq -r -e .product)
	log "  Product: $PRODUCT"
	INSTALLED_VERSION=$(echo $AGENT_INFO | jq -r .version)
	log "  Fetching current version from server ..."
	LATEST_VERSION=$(api_fetch_current_version $PRODUCT)
	# INSTALLED_VERSION is "null" if the agent doesn't know which version is installed
	if [ "$INSTALLED_VERSION" != "null" -a "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
		log "  Version $INSTALLED_VERSION is up to date"
		return 0
	fi

	# Get the update blob SHA256
	local LATEST_SHA256
	log "  Fetching manifest for version $LATEST_VERSION ..."
	LATEST_SHA256=$(api_fetch_blob_sha256 $PRODUCT $LATEST_VERSION)

	# Maybe we can use diff updates?
	local INSTALLED_SHA256 INSTALLED_PATH
	INSTALLED_SHA256=$(echo $AGENT_INFO | jq -r .sha256)
	INSTALLED_PATH=$(echo $AGENT_INFO | jq -r .path)

	# Start the update process ...
	log "  Installing blob $LATEST_SHA256 ..."
	api_fetch_blob $LATEST_SHA256 $INSTALLED_SHA256 $INSTALLED_PATH \
		| $AGENT install $LATEST_VERSION $LATEST_SHA256 2> >(while read LINE; do log "    $LINE"; done)
}

if [ $# -le 0 ]; then
	err "Usage: $0 [agent|agentdir]"
else
	ACTION=""
	if [ -d "$1" ]; then
		for AGENT in $(ls $1); do
			log "Running agent: $AGENT"
			ACTION="$ACTION $(trigger_update "$1/$AGENT")"
		done
	else
		log "Running agent: $1"
		ACTION="$ACTION $(trigger_update "$1")"
	fi

	# If one of the agents requested a reboot, we'll do so ...
	if echo $ACTION | grep -q REBOOT; then
		log "Schedule reboot ..."
		(sleep 3 && reboot) & </dev/null >/dev/null
	fi
fi
