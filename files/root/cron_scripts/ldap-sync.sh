#!/bin/bash
# SYNC LDAP FROM PRIMARY LDAP SERVER

# WAIT UP TO 5 MINUTES FOR RANDOM DELAY
WAIT=$((RANDOM % 6))
sleep ${WAIT}m

# DO NOT SYNC IF ANOTHER SYNC IN PROGRESS
test `ps auxxxxxww | grep 'ldap-sync' | grep -v grep | wc -l` -lt 2 \
  || ( logger -t 'ldap-sync' 'WARN - sync skipped (possibly another sync in progress)' ; exit )

# DO LDAP SYNC AND LOG OUTPUT
python /root/ldap-sync.py --clone-master | logger -t 'ldap-sync' 
