#!/bin/sh

# edit these to match your setup
. ./config.sh

cd "$base"
echo pulling new clamav image
docker pull clamav/clamav:stable_base || exit 1 

mkdir -p "$base/sockets"
mkdir -p "$base/signaturedb"

echo removing old clamd container
docker stop clamd || echo no container running 
docker rm clamd || echo no clamd container found
docker run \
    --name "clamd" \
    --memory="4g" \
    --volume "$base/signaturedb":/var/lib/clamav \
    --volume "/home/george":/scandir/home:ro \
    --mount type=bind,source=$base/sockets/,target=/tmp/ \
    -e CLAMAV_NO_FRESHCLAMD=true \
    -d \
    --restart always \
    --network host \
    clamav/clamav:stable_base
    
 docker logs -f clamd
