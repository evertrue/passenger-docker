FROM phusion/passenger-ruby22:0.9.19
MAINTAINER EverTrue <devops@evertrue.com>

WORKDIR /home/app/webapp

CMD ["/sbin/my_init"]

EXPOSE 8080

COPY nginx.conf /etc/nginx/sites-enabled/default

RUN apt-get update && apt-get install -y \
  jq \
  unzip
ADD https://s3.amazonaws.com/ops.evertrue.com/pkgs/vault_0.6.0_linux_amd64.zip \
  vault.zip
RUN unzip vault.zip -d /usr/local/bin

COPY bin /etc/my_init.d

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
