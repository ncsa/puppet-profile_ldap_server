# @summary Configure CRON jobs for LDAP services
#
# @example
#   include profile_ldap_server::crontab
class profile_ldap_server::crontab {

  File {
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }


  file { '/root/cron_scripts/ldap_connections.sh':
    source => "puppet:///modules/${module_name}/root/cron_scripts/ldap_connections.sh",
  }
  cron { 'ldap_connections':
    command     => '/root/cron_scripts/ldap_connections.sh',
    user        => 'root',
    minute      => '*/5',
    environment => ['SHELL=/bin/sh', 'MAILTO=ldap-admin@lists.ncsa.illinois.edu'],
  }

}
