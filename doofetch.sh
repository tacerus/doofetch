#!/bin/sh -Cef
# Image download tool
# Copyright (C) 2024  SUSE LLC <georg.pfuetzenreuter@suse.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

DISTCONF="${DISTCONF:-/etc/sysconfig/doofetch}"

# shellcheck source=doofetch.sysconfig
. "$DISTCONF"

if [ -z "$URL" ] || [ -z "$TARGETDIR" ] || [ -z "$TARGETLINK" ]
then
	echo 'Need URL, TARGETDIR and TARGETLINK.'
	exit 1
fi

if ! [ -d "$TARGETDIR" ]
then
	echo "$TARGETDIR is not a directory."
	exit 1
fi

COMPRESSION_SUFFIX="${URL##*.}"

case "$COMPRESSION_SUFFIX" in
	'xz' )
		COMPRESSION_SUFFIX=".$COMPRESSION_SUFFIX"
		UNCOMPRESS_CMD='unxz'
		echo 'Expecting XZ compression.'
		;;
	* )
		COMPRESSION_SUFFIX=''
		UNCOMPRESS_CMD=''
		echo 'Expecting no compression.'
		;;
esac

set -u

CURL='curl -fsS'

echo "Resolving $URL ..."
LOCATION="$($CURL -o /dev/null -w '%{redirect_url}' "$URL")"

LATEST_FILE="$(basename "$LOCATION" "$COMPRESSION_SUFFIX")"
echo "Latest file: $LATEST_FILE"
CURRENT_FILE="$(basename "$(readlink -e "$TARGETDIR/$TARGETLINK")")" || CURRENT_FILE=''
echo "Current file: $CURRENT_FILE"

if [ "$LATEST_FILE" = "$CURRENT_FILE" ]
then
	echo 'File is already up to date, bye.'
	exit 0
fi

echo "Loading $LOCATION ..."
for suffix in '' '.sha256' '.sha256.asc'
do
	$CURL -LOR --output-dir "$TARGETDIR" "${LOCATION}${suffix}"
done

LATEST_PATH="$TARGETDIR/$LATEST_FILE"
LATEST_COMPRESSED_PATH="${LATEST_PATH}${COMPRESSION_SUFFIX}"

echo 'Verifying ...'
gpg --verify "$LATEST_COMPRESSED_PATH".sha256.asc
cd "$TARGETDIR"
sha256sum -c "$LATEST_COMPRESSED_PATH".sha256

if [ -n "$UNCOMPRESS_CMD" ]
then
	echo 'Uncompressing ...'
	"$UNCOMPRESS_CMD" "$LATEST_COMPRESSED_PATH"
fi

if ! [ -f "$LATEST_PATH" ]
then
	echo 'File does not exist.'
	exit 1
fi

echo 'Linking ...'
ln -fsTv "$LATEST_FILE" "$TARGETLINK"

echo 'Update completed successfully.'
