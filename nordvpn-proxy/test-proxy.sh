#!/bin/sh

credentials="..."
proxy="$1"

curl -x "socks5://$proxy:1080" -U "$credentials" https://www.google.com
