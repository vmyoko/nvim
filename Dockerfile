FROM debian

ADD ./install.sh /root/.config/nvim/install.sh

RUN ["chmod", "+x", "/root/.config/nvim/install.sh"]

RUN /root/.config/nvim/install.sh

ADD . /root/.config/nvim

CMD ["/opt/nvim-linux-x86_64/bin/nvim"]
