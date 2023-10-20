#!/bin/sh

. ./config.sh

docker stop clamscan || echo clamscan container not running
docker rm clamscan || echo clamscan container not found
echo running clamscan

docker run -it --rm \
    --name "clamscan" \
    --volume $dirtoscan:/scandir:ro \
    --mount type=bind,source=$base/sockets/,target=/tmp/ \
    --user root \
    clamav/clamav:stable_base \
    clamdscan --multiscan --fdpass /scandir 2>&1 | grep FOUND
