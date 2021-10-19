#!/bin/bash
# LOG NUMBER OF CURRENT LDAP CONNECTIONS TO SYSLOG

LDAP_CONNECTIONS=`netstat -an | grep 636 | wc -l`
logger -t ns-slapd "current ldap connections: ${LDAP_CONNECTIONS}"
