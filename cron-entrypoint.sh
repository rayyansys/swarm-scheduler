#!/bin/bash

cat /crontab >> /etc/crontab
crontab /etc/crontab
crontab -l

# cron does not read env, save it here
env > /root/env

rsyslogd

exec "$@"
