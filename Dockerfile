FROM ubuntu:xenial
MAINTAINER Oliver Gugger <gugger@gmail.com>
MAINTAINER Xziy <mail@xziy.com>

ARG USER_ID
ARG GROUP_ID
ARG VERSION

ENV USER lili
ENV COMPONENT ${USER}
ENV HOME /${USER}

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} ${USER} \
    && useradd -u ${USER_ID} -g ${USER} -s /bin/bash -m -d ${HOME} ${USER}

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget software-properties-common \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && apt-add-repository ppa:bitcoin/bitcoin \
     && apt-get update && apt-get install -y libdb4.8-dev libdb4.8++-dev libzmq3-dev libminiupnpc-dev libprotobuf-dev protobuf-compiler libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libboost-all-dev libssl-dev libgmp3-dev libevent-dev\
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && gosu nobody true

ENV VERSION ${VERSION:-1.1}
RUN mkdir -p /opt/${COMPONENT} \
    && wget -O /opt/${COMPONENT}/${COMPONENT}d "http://cd.m42.cx:1180/masternodes/lili/src/lilid" \
    && wget -O /opt/${COMPONENT}/${COMPONENT}-cli "http://cd.m42.cx:1180/masternodes/lili/src/lili-cli" \
    && chmod +x /opt/${COMPONENT}/*
#RUN set -x \
#    && apt-get update && apt-get install -y libminiupnpc-dev python-virtualenv git virtualenv cron \
#    && mkdir -p /sentinel \
#    && cd /sentinel \
#    && git clone https://github.com/terracoin/sentinel.git . \
#    && virtualenv ./venv \
#    && ./venv/bin/pip install -r requirements.txt \
#    && touch sentinel.log \
#    && chown -R ${USER} /sentinel \
#    && echo '* * * * * '${USER}' cd /sentinel && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py >> sentinel.log 2>&1' >> /etc/cron.d/sentinel \
#    && chmod 0644 /etc/cron.d/sentinel \
#    && touch /var/log/cron.log

EXPOSE 44100 44101

VOLUME ["${HOME}"]
WORKDIR ${HOME}
ADD ./bin /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start-unprivileged.sh"]
