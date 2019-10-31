#!/bin/sh

zbarimg --raw part.*.png | base64 --decode >> "$1" 

#xargs -n 1 zbarimg "$1" >> out
