#!/bin/sh

PART_SIZE=2048
split "$1" --bytes=$PART_SIZE -d part.
find part.* -exec sh -c 'base64 {} | (qrencode -o {}.png && rm {})' \;
