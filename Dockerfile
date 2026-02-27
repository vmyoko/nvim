FROM archlinux

RUN mkdir /root/.config/
RUN mkdir /root/.config/nvim

ADD . /root/.config/nvim/

WORKDIR /root/
