FROM ubuntu:16.04

MAINTAINER Niklas Rust <rust@qabel.de>
ENV AGENT_DIR  /opt/buildAgent
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && \
    locale-gen

RUN apt update && \
	 apt -y install --no-install-recommends software-properties-common && \
	 apt-add-repository ppa:webupd8team/java && \
	 apt update && \
	 echo debconf shared/accepted-oracle-license-v1-1 select true |  debconf-set-selections && \
	 apt -y install --no-install-recommends sudo libffi-dev postgresql-9.5 libpq-dev python3.5 python3-virtualenv virtualenv python3-pip redis-server redis-tools unzip file qt5-default git gcc-multilib g++-multilib xvfb fluxbox build-essential curl wget lib32stdc++6 lib32z1 oracle-java8-installer expect chromium-browser &&  \ 
    pip3 install -U pip setuptools wheel spinx && \
	curl -sL https://deb.nodesource.com/setup_7.x | bash -  && \
	apt-get install --no-install-recommends -y nodejs && \	
	 apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY tools /opt/tools
ENV PATH ${PATH}:/opt/tools
RUN mkdir /opt/android-sdk && cd /opt/android-sdk && wget --output-document=android-sdk.zip --quiet https://dl.google.com/android/repository/tools_r25.2.3-linux.zip && \
  unzip android-sdk.zip && \
  rm -f android-sdk.zip && \
  chown -R root.root . && \
  /opt/tools/android-accept-licenses.sh "tools/bin/sdkmanager build-tools;24.0.3 ndk-bundle platform-tools platforms;android-24 tools" 

ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN echo y | android --silent update sdk --no-ui --all --filter sys-img-x86_64-google_apis-24

RUN echo "no" | android create avd \
                --force \
                --device "Nexus 5" \
                --name test \
                --target "android-24" \
                --abi google_apis/x86_64 \
                --skin "1080x1920" \
                --sdcard 512M

COPY licenses /opt/android-sdk/licenses
ENV GOSU_VERSION 1.10
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
RUN adduser --disabled-password --gecos "" qabel \
	&& sed -i -e "s/%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/" /etc/sudoers \
	&& usermod -a -G sudo qabel \
	&& mkdir /home/qabel/.ssh 


COPY conf/id_ed25519 /home/qabel/.ssh
COPY conf/sshconfig /home/qabel/.ssh/config
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh 
CMD ["/docker-entrypoint.sh"]
VOLUME /opt/buildAgent
EXPOSE 9090

