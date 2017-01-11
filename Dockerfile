FROM ubuntu:16.04

MAINTAINER Niklas Rust <rust@qabel.de>

VOLUME /data/teamcity_agent/conf
ENV CONFIG_FILE /data/teamcity_agent/conf/buildAgent.properties
LABEL dockerImage.teamcity.version="latest" \
      dockerImage.teamcity.buildNumber="latest"

COPY dist/buildagent /opt/buildagent
COPY run-agent.sh /run-agent.sh
COPY run-services.sh /run-services.sh

RUN apt update && \
	 apt -y install --no-install-recommends software-properties-common && \
	 apt-add-repository ppa:webupd8team/java && \
	 apt update && \
	 echo debconf shared/accepted-oracle-license-v1-1 select true |  debconf-set-selections && \
	 apt -y install libffi-dev postgresql-9.5 libpq-dev python3.5 python3-virtualenv virtualenv python3-pip redis-server redis-tools unzip file qt5-default git gcc-multilib g++-multilib xvfb fluxbox build-essential curl wget lib32stdc++6 lib32z1 oracle-java8-installer expect chromium-browser &&  \ 
    pip3 install -U pip setuptools wheel && \
	curl -sL https://deb.nodesource.com/setup_7.x | bash -  && \
	apt-get install -y nodejs && \	
	 apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY tools /opt/tools

ENV PATH ${PATH}:/opt/tools
RUN useradd -mp "" qabel

RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && \
    locale-gen

# Install Android SDK
RUN mkdir /opt/android-sdk && cd /opt/android-sdk && wget --output-document=android-sdk.zip --quiet https://dl.google.com/android/repository/tools_r25.2.3-linux.zip && \
  unzip android-sdk.zip && \
  rm -f android-sdk.zip && \
  chown -R root.root . && \
  /opt/tools/android-accept-licenses.sh "tools/bin/sdkmanager build-tools;24.0.3 ndk-bundle platform-tools platforms;android-24 tools" 


# Setup environment
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN echo y | android --silent update sdk --no-ui --all --filter sys-img-x86_64-google_apis-24

# Create emulator
RUN echo "no" | android create avd \
                --force \
                --device "Nexus 5" \
                --name test \
                --target "android-24" \
                --abi google_apis/x86_64 \
                --skin "1080x1920" \
                --sdcard 512M

#copy licenses
COPY licenses /opt/android-sdk/licenses
RUN useradd -m buildagent && \
    chmod +x /run-agent.sh /run-services.sh

CMD ["/run-services.sh"]

EXPOSE 9090

