FROM ubuntu:18.04

EXPOSE 1080
RUN mkdir /nordvpn-proxy
RUN apt update && apt install -y haproxy curl jq
COPY find-proxy.sh /nordvpn-proxy/
COPY haproxy.template /nordvpn-proxy/
COPY run-proxy.sh /nordvpn-proxy/
RUN chmod a+x /nordvpn-proxy/*.sh
RUN mkdir /run/haproxy/
RUN touch /run/haproxy/admin.sock

WORKDIR /nordvpn-proxy
ENTRYPOINT ["/nordvpn-proxy/run-proxy.sh"]	
