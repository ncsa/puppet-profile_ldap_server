#!/bin/bash
# TEMP FIX TO ROTATE LDAP SYSLOGS

find /var/log/ -maxdepth 1 -name 'messages' -type f -size +400M  -exec /usr/sbin/logrotate -s /var/lib/logrotate/logrotate.status /etc/logrotate.conf \; 

