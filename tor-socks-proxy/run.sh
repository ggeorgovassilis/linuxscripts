#!/bin/bash

docker stop torproxy || true
docker rm torproxy || true
docker run -d --name torproxy -p 8080:8080 -v ./torrc:/etc/tor/torrc:ro tor-socks-proxy
docker logs -f torproxy
