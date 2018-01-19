# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# ------------------------------------------------------------------------------
# Pull base image.
FROM kdelfour/supervisor-docker
MAINTAINER Kevin Delfour <kevin@delfour.eu>

# ------------------------------------------------------------------------------
# Install base
RUN apt-get update
RUN apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs cpanminus
RUN apt-get install -y makepasswd rcs perl-doc libio-tee-perl git libmail-imapclient-perl libdigest-md5-file-perl libterm-readkey-perl libfile-copy-recursive-perl build-essential make automake libunicode-string-perl
RUN sudo apt-get install -y libauthen-ntlm-perl libcrypt-ssleay-perl libdigest-hmac-perl libfile-copy-recursive-perl libio-compress-perl libio-socket-inet6-perl libio-socket-ssl-perl libio-tee-perl libmodule-scandeps-perl libnet-ssleay-perl libpar-packer-perl libterm-readkey-perl libtest-pod-perl libtest-simple-perl libunicode-string-perl liburi-perl cpanminus
RUN cpanm "Class::Load Crypt::OpenSSL::RSA Data::Uniqid Dist::CheckConflicts JSON JSON::WebToken JSON::WebToken::Crypt::RSA Module::Implementation Module::Runtime Package::Stash Package::Stash::XS Readonly Sys::MemInfo Test::Fatal Test::Mock::Guard Test::MockObject Test::Requires Try::Tiny"
RUN cpanm "Crypt::OpenSSL::RSA Data::Uniqid JSON JSON::WebToken JSON::WebToken::Crypt::RSA Readonly Sys::MemInfo Test::Mock::Guard Test::MockObject"
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
RUN useradd user
RUN mkdir /home/user
RUN chown user /home/user
RUN su user
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl https://install.meteor.com/ | sh

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
EXPOSE 3000
# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-u", "user"]
