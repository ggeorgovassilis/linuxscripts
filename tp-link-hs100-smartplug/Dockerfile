FROM ubuntu:18.04
# USER root

RUN mkdir /hs100
RUN apt update
RUN apt install -y netcat
COPY hs100.sh /hs100/hs100.sh
ENTRYPOINT ["/hs100/hs100.sh"]
