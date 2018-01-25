# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
From ubuntu16.04
MAINTAINER Almagest fraternite <almagestfraternite@gmail.com>

# ------------------------------------------------------------------------------
# Install base
RUN apt-get update

RUN sudo apt get update && apt install -y apache2 openssh-server supervisor
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor

RUN useradd user
RUN mkdir /home/user
RUN chown user /home/user

RUN echo 'root:almagest1298' | chpasswd
RUN echo 'user:almagest1298' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs cpanminus 
RUN apt-get install -y makepasswd rcs perl-doc libio-tee-perl git libmail-imapclient-perl libdigest-md5-file-perl libterm-readkey-perl libfile-copy-recursive-perl build-essential make automake libunicode-string-perl
RUN apt-get install -y libauthen-ntlm-perl libcrypt-ssleay-perl libdigest-hmac-perl libfile-copy-recursive-perl libio-compress-perl libio-socket-inet6-perl libio-socket-ssl-perl libio-tee-perl libmodule-scandeps-perl libnet-ssleay-perl libpar-packer-perl libterm-readkey-perl libtest-pod-perl libtest-simple-perl libunicode-string-perl liburi-perl cpanminus
# Set the locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

RUN cpanm "Class::Load"
RUN cpanm "Crypt::OpenSSL::RSA"
RUN cpanm "Data::Uniqid"
RUN cpanm "Dist::CheckConflicts"
RUN cpanm "JSON"
RUN cpanm "JSON::WebToken"
RUN cpanm "JSON::WebToken::Crypt::RSA"
RUN cpanm "Module::Implementation"
RUN cpanm "Module::Runtime"
RUN cpanm "Package::Stash"
RUN cpanm "Package::Stash::XS"
RUN cpanm "Readonly"
RUN cpanm "Sys::MemInfo"
RUN cpanm "Test::Fatal"
RUN cpanm "Test::Mock::Guard"
RUN cpanm "Test::MockObject"
RUN cpanm "Test::Requires"
RUN cpanm "Try::Tiny"

RUN export PERL_MM_USE_DEFAULT=1
RUN perl -MCPAN -e 'install Unicode::String'
RUN git clone git://github.com/imapsync/imapsync.git
RUN cd imapsync
RUN mkdir dist
RUN make install
# ------------------------------------------------------------------------------
# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs
    
# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl https://install.meteor.com/ | sh

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
EXPOSE 3000
# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-u", "user"]
