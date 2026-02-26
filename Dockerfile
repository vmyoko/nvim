FROM debian

RUN apt update && apt upgrade && apt install -y curl && apt install make -y && apt install git -y
RUN mkdir /root/.config/
RUN mkdir /root/.config/nvim
RUN git clone https://github.com/vmyoko/nvim.git /root/.config/nvim

WORKDIR /root/
