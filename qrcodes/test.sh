#!/bin/sh

./make-qr.sh "$1"
./restore-qr.sh out.bin
cmp --silent "$1" out.bin || echo "files are different"
