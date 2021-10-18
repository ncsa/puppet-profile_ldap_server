#!/bin/bash

grep slapd /var/log/secure | \
  grep authentication | awk '{ print $1 " " $2 " " $3 " " $10 }' | awk -F\' '{ print $1 " " $2 }' | \
  grep -v 'ldap-bind' | \
  tail -75 | awk '{ print $NF }' | sort | uniq -c | sort -rn | \
  column -t
