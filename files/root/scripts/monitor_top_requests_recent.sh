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

most_active_requestors () {
  local LIST_OF_CLIENTS=`egrep -i '\sconnection from\s' $ACCESSLOGPATH/$ACCESSLOG* | awk '{ print $(NF-2) }' | sort -V | uniq | grep -iv unknown `
  while IFS= read -r line; do
    local IP=`echo $line | awk '{ print $1 }'`
    # GET LIST OF CONNECTIONS
    local LIST_OF_CONNECITONS=`egrep -i "\sconnection from $IP\s" $ACCESSLOGPATH/$ACCESSLOG* | awk -F\: '{ print $NF }' | awk '{ print $3 }' | awk -F\= '{ print $NF}' | sort | uniq | tr '\n' '|' | sed 's/.$//'`
    # GET COUNT OF QUERIES FOR ANY CONNECTIONS
    local COUNT=`egrep -i "\sconn\=($LIST_OF_CONNECITONS)\s" $ACCESSLOGPATH/$ACCESSLOG* | wc -l `
    echo -n $COUNT
    echo -n ' '
    hostname_of_ip $IP
  done <<< "$LIST_OF_CLIENTS"
}

ldap_access_log
most_active_requestors | sort -rn | tail -30 | column -t

