# @summary Configure CRON jobs for LDAP services
#
# @example
#   include profile_ldap_server::crontab
class profile_ldap_server::crontab {

# LOG NUMBER OF LDAP CLIENT CONNECTIONS TO SYSLOG
# */5 * * * * ((echo -n 'current ldap connections: ' && netstat -an | grep 636 | awk '{ print $5 }' | awk -F\: '{ print $1 }' | wc -l) | logger -t ns-slapd)
  cron { 'ldap_connections':
    command     => '((echo -n \'current ldap connections: \' && netstat -an | grep 636 | awk \'{ print \$5 }\' | awk -F\\\: \'{ print \$1 }\' | wc -l) | logger -t ns-slapd)',
    user        => 'root',
    minute      => '*/5',
    environment => ['SHELL=/bin/sh', 'MAILTO=ldap-admin@lists.ncsa.illinois.edu'],
  }

  cron { 'ldap-sync':
    command     => 'sleep \$((RANDOM \\\% 5))m && test `ps auxxxxxww | grep \'ldap-sync\' | grep -v grep | wc -l` -lt 2 && python /root/ldap-sync.py --clone-master | logger -t \'ldap-sync\' || logger -t \'ldap-sync\' \'WARN - sync skipped (possibly another sync in progress)\'',
    user        => 'root',
    minute      => '*/20',
    environment => ['SHELL=/bin/sh'],
  }

  file { '/root/scripts/rotate-ldap-logs.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/rotate-ldap-logs.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => [
      File['/root/scripts'],
    ],
  }
  cron { 'Rotate LDAP syslog scripts':
    command => '/root/scripts/rotate-ldap-logs.sh',
    user    => 'root',
    minute  => [
      15,
      30,
      45,
    ],
    require => [
      File['/root/scripts/rotate-ldap-logs.sh'],
    ],
  }

}
