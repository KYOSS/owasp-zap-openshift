# This dockerfile builds the zap stable release
FROM centos:centos7
MAINTAINER Deven Phillips <deven.phillips@redhat.com>

RUN yum install -y epel-release
RUN yum install -y redhat-rpm-config \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel \
    java-1.8.0-openjdk ruby wget curl \
    xmlstarlet unzip git x11vnc \
    xorg-x11-server-Xvfb openbox xterm \
    net-tools ruby-devel python-pip \
    firefox

RUN pip install --upgrade pip
RUN gem install zapr
RUN pip install zapcli
# Install latest dev version of the python API
RUN pip install python-owasp-zap-v2.4

RUN mkdir -p /home/zap 
WORKDIR /home/zap
RUN chown root:root /home/zap -R

#Change to the zap user so things get done as the right person (apart from copy)

RUN mkdir -p /var/lib/jenkins/.vnc

ENV HOME=/var/lib/jenkins

RUN yum clean all && \
    export INSTALL_PKGS="nss_wrapper java-1.8.0-openjdk-headless \
        java-1.8.0-openjdk-devel nss_wrapper gettext tar git" && \
    yum clean all && \
    yum install -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/jenkins && \
    chown -R root:root /var/lib/jenkins && \
    chmod -R g+w /var/lib/jenkins

# Copy the entrypoint
COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client

# Download and expand the latest stable release 
RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions-dev.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -q --content-disposition -i - -O - | tar zx && \
	cp -R ZAP*/* . &&  \
	rm -R ZAP* && \
	curl -s -L https://bitbucket.org/meszarv/webswing/downloads/webswing-2.3-distribution.zip > webswing.zip && \
	unzip -q *.zip && \
	rm *.zip && \
	touch AcceptedLicense

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/home/zap:$PATH
ENV ZAP_PATH /home/zap/zap.sh

# Default port for use with zapcli
ENV ZAP_PORT 8080

COPY zap-x.sh /home/zap/ 
COPY zap-* /home/zap/ 
COPY zap_* /home/zap/ 
COPY webswing.config /home/zap/webswing-2.3/ 
COPY policies /var/lib/jenkins/.ZAP/policies/
COPY .xinitrc /var/lib/jenkins/

RUN chown root:root /home/zap/zap-x.sh && \
	chown root:root /home/zap/zap-baseline.py && \
	chown root:root /home/zap/zap-webswing.sh && \
	chown root:root /home/zap/webswing-2.3/webswing.config && \
	chown root:root -R /var/lib/jenkins/.ZAP/ && \
	chown root:root /var/lib/jenkins/.xinitrc && \
	chmod 777 /var/lib/jenkins -R && \
	chmod 777 /home/zap -R && \
	chown root:root /var/lib/jenkins -R
RUN chmod 777 /var/lib/jenkins -R
RUN mkdir -p /zap/wrk && \
    chmod 777 /zap/wrk && \
    sync

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
