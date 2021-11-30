#!/usr/bin/env bash

# Some notes on error handling:
# These options ensure that the script exits if one SIMPLE command returns
# a non-zero return code. SIMPLE commands are:
# - lines without "local"
# - lines without "&&", "||", "while", "until", "!" (and maybe more?)
set -eo pipefail
shopt -s inherit_errexit
# product in Git heißt samr30
PRODUCT="dummy"
FILENAME=$(basename -- $0)
FILEPATH=/home/pi/SSV-SDU-GUC-AGENT

get_sha256 () {
	local FILE=$1
	sha256sum $FILE | cut -d " " -f 1
}

get_info () {
	if [ -e "$FILENAME" ]; then
		local VERSION SHA256 FILEPATH
		VERSION="$(cat $FILENAME)"
		FILEPATH="$FILENAME-$VERSION"
		FILESHA256="$(get_sha256 $FILEPATH)"
		echo "{\"product\": \"$PRODUCT\", \"version\": \"$VERSION\", \"sha256\": \"$FILESHA256\", \"path\": \"$FILEPATH\"}"
	else
		echo "{\"product\": \"$PRODUCT\"}"
	fi
}

install_update () {
	local VERSION=$1
	local EXPECTED_SHA256=$2

	# Store update in file
	cat >$FILENAME-$VERSION

	# Check SHA256
	local SHA256
	SHA256=$(get_sha256 $FILENAME-$VERSION)
	[ "$EXPECTED_SHA256" != "$SHA256" ] && return 3

	# Store current version
	echo -n $VERSION >$FILENAME

	# extract bin from .tar and return extracted filename
	local UpdateFile=$(tar -xvf $FILENAME-$VERSION)

	# flash *.bin to samr30 via edbg
	# ~/path/to/edbg -t $BOARD -p -f ~/path/to/*.bin to be installed or flashed
	# /home/pi/ instead of ~ for systemd to be able to find path
	# in this case an example Hello World is used
	/home/pi/bin/edbg -t samr30 -pv -f /home/pi/$UpdateFile	
	# end
	echo -e "$(date -u) samr updated to $VERSION\n" >>FILEPATH/agent/samr30/assets/examples/sam-r30/logfile_samr30_fw-update.txt
}

case $1 in
	info)
		get_info
		;;
	install)
		install_update $2 $3
		;;
esac
