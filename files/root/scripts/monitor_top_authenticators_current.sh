#!/bin/bash

ldap_access_log () {
  ACCESSLOGPATH=`find /var/log/dirsrv -type d | grep "ldap"`
  ACCESSLOG=`ls -1rt "$ACCESSLOGPATH" | grep access | tail -1`
  SECURELOG="/var/log/secure"
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

most_active_authenticators () {
  grep -q slapd $SECURELOG || exit;
  local LIST_OF_KRBAUTHS=`grep slapd $SECURELOG | grep authentication | grep -v 'ldap-bind' | tail -75`
  local TEMPFILE_IPS=`mktemp`
  while IFS= read -r KRBAUTH; do
    #echo $KRBAUTH
    USER=`echo "$KRBAUTH" | awk '{ print $10 }' | awk -F\' '{ print $2 }'`
    TIMESTAMP=`echo "$KRBAUTH" | awk '{ print $3 }' | head -c 6 `
#    echo "$USER" $TIMESTAMP
    CONNSTRING=`grep "$TIMESTAMP" $ACCESSLOGPATH/$ACCESSLOG | grep "$USER" | awk '{ print $3 }' | sort | uniq | head -1`
#    grep "$CONNSTRING" $ACCESSLOGPATH/$ACCESSLOG | egrep -i '\sconnection from\s' | awk '{ print $(NF-2) }' | sort -V | uniq | grep -iv unknown
    #grep "$CONNSTRING" $ACCESSLOGPATH/$ACCESSLOG | egrep -i '\sconnection from\s' | awk '{ print $(NF-2) }' | sort -V | uniq | grep -iv unknown >> $TEMPFILE_IPS
    grep -B50 "$TIMESTAMP" $ACCESSLOGPATH/$ACCESSLOG | grep -B20 "$USER" | grep "$CONNSTRING" | egrep -i '\sconnection from\s' | awk '{ print $(NF-2) }' | sort -V | uniq | grep -iv unknown >> $TEMPFILE_IPS
  done <<< "$LIST_OF_KRBAUTHS"
  # BUILD LIST OF BIND CONNECTION CLIENT IPS WITH UNIQ COUNT
  local LIST_OF_BIND_CONNECTORS=`sort $TEMPFILE_IPS | uniq -c | sort -rn | head -10`
  rm -f $TEMPFILE_IPS
  # LOOKUP IPS
  while IFS= read -r line; do
    COUNT=`echo $line | awk '{ print $1 }'`
    IP=`echo $line | awk '{ print $2 }'`
    echo -n $COUNT
    echo -n ' '
    hostname_of_ip $IP
  done <<< "$LIST_OF_BIND_CONNECTORS"
}

ldap_access_log
most_active_authenticators | column -t
