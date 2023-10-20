#!/bin/sh

# edit these to match your setup
. ./config.sh

cd "$base"
echo pulling new clamav image
docker pull clamav/clamav:stable || exit 1 

mkdir -p "$base/sockets"
mkdir -p "$base/signaturedb"


chmod -R a+rwx "$base/sockets"
chmod -R a+rwx "$base/signaturedb"

echo removing old clamd container
docker stop clamd || echo no container running 
docker rm clamd || echo no clamd container found
docker run \
    --name "clamd" \
    --volume "$base/signaturedb":/var/lib/clamav \
    --volume "$dirtoscan":/scandir:ro \
    --mount type=bind,source=$base/sockets/,target=/tmp/ \
    -d \
    --restart always \
    --network host \
    clamav/clamav:stable
