FROM debian

RUN apt update && apt upgrade && apt install -y curl

WORKDIR /root/
