#!/bin/sh
find -type f -exec md5sum -t {} \; | cut -d ' ' -f 1 | sort | md5sum
