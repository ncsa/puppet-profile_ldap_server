#!/bin/bash

ldap_access_log () {
  ACCESSLOGPATH=`find /var/log/dirsrv -type d | grep "ldap"`
  ACCESSLOG=`ls -1rt "$ACCESSLOGPATH" | grep access | tail -1`
  #echo "log file: $ACCESSLOGPATH/$ACCESSLOG"
}

hostname_of_ip () {
  local NSLOOKUP_RESULT=`nslookup $1`
  if `echo $NSLOOKUP_RESULT | grep -q name`; then
    echo $NSLOOKUP_RESULT | grep name | awk '{ print $NF }' | head -1 | sed 's/.$//'
  else
    echo $1
  fi
}

most_active_connectors () {
  local LIST_OF_CLIENTS=`egrep -i '\sconnection from\s' $ACCESSLOGPATH/$ACCESSLOG | awk '{ print $(NF-2) }' | sort -V | uniq -c | grep -iv unknown | sort -rn | head -30`
  while IFS= read -r line; do
    COUNT=`echo $line | awk '{ print $1 }'`
    IP=`echo $line | awk '{ print $2 }'`
    echo -n $COUNT
    echo -n ' '
    hostname_of_ip $IP
  done <<< "$LIST_OF_CLIENTS"
}

ldap_access_log
most_active_connectors | column -t
