FROM ubuntu

RUN apt update

RUN apt install snapd -y

RUN systemctl enable snapd

STOPSIGNAL SIGRTMIN+3

ADD ./install.sh /root/.config/nvim/install.sh

RUN ["chmod", "+x", "/root/.config/nvim/install.sh"]

RUN /root/.config/nvim/install.sh

ADD . /root/.config/nvim

CMD ["/sbin/init"]
