# tag as: scheduler
FROM ruby:2.3

MAINTAINER Hossam Hammady <github@hammady.net>

# install cron & curl
RUN apt-get update && \
    apt-get install -y \
        cron rsyslog && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root
COPY Gemfile /root/Gemfile
RUN bundle install

RUN echo 'cron.*                /var/log/cron.log' >> /etc/rsyslog.conf

COPY run-task.sh /usr/bin/run-task
COPY run-task.rb /root/run-task.rb 
COPY cron-entrypoint.sh /usr/bin/cron-entrypoint.sh
ENTRYPOINT ["cron-entrypoint.sh"]

CMD ["cron", "-f"]
