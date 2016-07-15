FROM phusion/passenger-ruby22:0.9.19
MAINTAINER EverTrue <devops@evertrue.com>

WORKDIR /home/app/webapp

CMD ["/sbin/my_init"]

EXPOSE 8080

COPY nginx.conf /etc/nginx/sites-enabled/default

RUN gem install vault -v 0.4.0

COPY bin /etc/my_init.d

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
