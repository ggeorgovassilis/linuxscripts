#!/bin/sh

echo running freshclam

. ./config.sh

cd "$base"


docker run -it --rm \
    --name "freshclam" \
    --mount type=bind,source=$base/sockets/,target=/tmp/ \
    --user root \
    --network host\
    clamav/clamav:stable_base \
    freshclam
