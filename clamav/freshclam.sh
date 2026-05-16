#!/bin/sh

echo running freshclam

. ./config.sh

cd "$base"
mkdir -p "$base/signaturedb"

docker run -it --rm \
    --name "freshclam" \
    --volume "$base/signaturedb":/var/lib/clamav \
    --user root \
    --network host \
    clamav/clamav:stable_base \
    freshclam
