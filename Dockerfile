FROM rustscan/rustscan:1.10.0 as rustcandocker

FROM debian:stretch

MAINTAINER Nitrax <nitrax@lokisec.fr>

RUN apt-get update && apt-get install --yes curl gpg

# Adding Kali repository
RUN echo 'deb http://http.kali.org/kali kali-rolling main contrib non-free' >> /etc/apt/sources.list
RUN echo 'deb-src http://http.kali.org/kali kali-rolling main contrib non-free' >> /etc/apt/sources.list#

# Keli gpg keys
RUN gpg --keyserver hkp://keys.gnupg.net --recv-key 7D8D0BF6
RUN gpg -a --export 7D8D0BF6 | apt-key add -

# Requirements
RUN apt-get update && apt-get -y install fish build-essential git libswitch-perl liblwp-useragent-determined-perl wget tmux vim locales emacs net-tools netcat  \
    python-pip=9.0.1-2+deb9u2 python-pip-whl=9.0.1-2+deb9u2 python-all-dev python-setuptools python-wheel

# Installing tools
RUN apt-get -y install  dirb john p0f patator dotdotpwn enum4linux dnsenum smtp-user-enum wordlists hydra snmpcheck hping3 wafw00f crunch medusa set wpscan httrack nmap sslscan sqlmap joomscan theharvester webshells tcpdump openvpn nikto proxychains htop telnet gobuster bloodhound

# Setting and lauching postgresql
ADD ./conf/database.sql /tmp/
RUN /etc/init.d/postgresql start && su postgres -c "psql -f /tmp/database.sql"
USER root
ADD ./conf/database.yml /usr/share/metasploit-framework/config/

# Setting fish shell
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_9.0/ /' | tee /etc/apt/sources.list.d/shells:fish:release:3.list
RUN curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_9.0/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/shells:fish:release:3.gpg > /dev/null
RUN apt update
RUN apt -y install fish
ADD conf/conf.fish /root/.config/fish/conf.d/

WORKDIR /opt

# Install oh-my-fish
RUN git clone https://github.com/oh-my-fish/oh-my-fish omf
RUN /opt/omf/bin/install --offline --noninteractive
RUN echo "omf install godfather" | fish

# Setting tmux
ADD conf/locale.gen /etc/
ADD conf/.tmux.conf /root/
RUN locale-gen

# Setting proxy dns
RUN git clone https://github.com/jtripper/dns-tcp-socks-proxy.git dns
WORKDIR /opt/dns
RUN make
ADD conf/dns_proxy.conf /opt/dns/
ADD conf/resolv.conf /opt/dns

# Setting proxychains
ADD conf/proxychains.conf /etc/

# Install Nessus
RUN wget 'https://www.tenable.com/downloads/api/v1/public/pages/nessus/downloads/11658/download?i_agree_to_tenable_license_agreement=true' -O nessus.deb \
    && dpkg -i nessus.deb \
    && rm nessus.deb
# Start Nessus with /opt/nessus/sbin/nessus-service

# Install rustscan
COPY --from=rustcandocker /usr/local/bin/rustscan /usr/local/bin/rustscan

# Create /dev/net/tun for OpenVPN.
RUN mkdir -p /dev/net && \
    mknod /dev/net/tun c 10 200 && \
    chmod 600 /dev/net/tun

# Setting shared folder
VOLUME /tmp/data

COPY docker-entrypoint.sh /docker-entrypoint.sh

WORKDIR /tmp/data

COPY motd /etc/motd

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/bin/bash" ]