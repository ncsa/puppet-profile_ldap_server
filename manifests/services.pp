# @summary Configure services for LDAP server
#
# @param packages_absent
#   List of packages to ensure absent
#
# @param packages_present
#   List of packages to ensure present
#
# @param pam_authtype
#   Authtype to use in pam
#
# @example
#   include profile_ldap_server::services
class profile_ldap_server::services (
  Array[String] $packages_absent,
  Array[String] $packages_present,
  String $pam_authtype,
) {

  ensure_packages($packages_present, {'ensure' => 'present'})
  ensure_packages($packages_absent, {'ensure' => 'absent'})

# Depends upon the /etc/dirsrv/slapd-ncsa-ldap file.
  service { 'dirsrv@ncsa-ldap':
      ensure => running,
      enable => true,
  }

#NOTE:  This class' configuration of hosts.allow and hosts.deny could conflict with other
#       definitions for them in other classes.
  file { '/etc/hosts.allow':
    source => "puppet:///modules/${module_name}/etc/hosts.allow",
    mode   => '0644',
  }

  file { '/etc/hosts.deny':
    source => "puppet:///modules/${module_name}/etc/hosts.deny",
    mode   => '0644',
  }

  file { '/etc/security/limits.conf':
    source => "puppet:///modules/${module_name}/etc/security/limits.conf",
    mode   => '0644',
  }

  file { '/etc/sysconfig/dirsrv.systemd':
    source => "puppet:///modules/${module_name}/etc/sysconfig/dirsrv.systemd",
    mode   => '0644',
  }

  file { '/etc/rsyslog.d/dirsrv.conf':
    source => "puppet:///modules/${module_name}/etc/rsyslog.d/dirsrv.conf",
    mode   => '0644',
  }

# MOVED TO common::syslog
#  file { '/etc/logrotate.conf':
#    source => "puppet:///modules/${module_name}/etc/logrotate.conf",
#    mode => '644',
#  }

  file { '/etc/logrotate.d/syslog':
    source => "puppet:///modules/${module_name}/etc/logrotate.d/syslog",
    mode   => '0644',
  }

  $krbpkgs = [
    'pam_krb5',
  ]
  ensure_packages( $krbpkgs )

  file { '/etc/pam.d/ldapserver.new':
    source => "puppet:///modules/${module_name}/etc/pam.d/ldapserver.${pam_authtype}",
    mode   => '0644',
  }

  file { '/etc/pam.d/ldapserver':
    ensure => 'link',
    target => 'ldapserver.new',
  }

  file { '/etc/cron.hourly/logrotate':
    ensure => 'link',
    target => '/etc/cron.daily/logrotate',
  }

  file { '/etc/dirsrv/schema/98voperson.ldif':
    source => "puppet:///modules/${module_name}/etc/dirsrv/schema/98voperson.ldif",
    mode   => '0444',
  }

  file { '/etc/dirsrv/schema/05rfc2927.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/05rfc2927.ldif',
  }

  file { '/etc/dirsrv/schema/10automember-plugin.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/10automember-plugin.ldif',
  }

  file { '/etc/dirsrv/schema/10mep-plugin.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/10mep-plugin.ldif',
  }

  file { '/etc/dirsrv/schema/10rfc2307.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/10rfc2307.ldif',
  }

  file { '/etc/dirsrv/schema/20subscriber.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/20subscriber.ldif',
  }

  file { '/etc/dirsrv/schema/25java-object.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/25java-object.ldif',
  }

  file { '/etc/dirsrv/schema/50ns-admin.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/50ns-admin.ldif',
  }

  file { '/etc/dirsrv/schema/50ns-certificate.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/50ns-certificate.ldif',
  }

  file { '/etc/dirsrv/schema/50ns-value.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/50ns-value.ldif',
  }

  file { '/etc/dirsrv/schema/50ns-web.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/50ns-web.ldif',
  }

  file { '/etc/dirsrv/schema/60acctpolicy.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60acctpolicy.ldif',
  }

  file { '/etc/dirsrv/schema/60autofs.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60autofs.ldif',
  }

  file { '/etc/dirsrv/schema/60eduperson.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60eduperson.ldif',
  }

  file { '/etc/dirsrv/schema/60nss-ldap.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60nss-ldap.ldif',
  }

  file { '/etc/dirsrv/schema/60pureftpd.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60pureftpd.ldif',
  }

  file { '/etc/dirsrv/schema/60rfc2739.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60rfc2739.ldif',
  }

  file { '/etc/dirsrv/schema/60trust.ldif':
    ensure => 'link',
    target => '/usr/share/dirsrv/schema/60trust.ldif',
  }

  file { '/root/enableMemberOf.ldif':
    source => "puppet:///modules/${module_name}/root/enableMemberOf.ldif",
    mode   => '0600',
  }

  file { '/root/setToUniqueMember.ldif':
    source => "puppet:///modules/${module_name}/root/setToUniqueMember.ldif",
    mode   => '0600',
  }

  file { '/root/enableInetUser.ldif':
    source => "puppet:///modules/${module_name}/root/enableInetUser.ldif",
    mode   => '0600',
  }

  file { '/root/enablePamPassthrough.ldif':
    source => "puppet:///modules/${module_name}/root/enablePamPassthrough.ldif",
    mode   => '0600',
  }

  file { '/root/limits.ldif':
    source => "puppet:///modules/${module_name}/root/limits.ldif",
    mode   => '0600',
  }

  file { '/root/ds389setup.inf':
    source => "puppet:///modules/${module_name}/root/ds389setup.inf",
    mode   => '0600',
  }

  file { '/root/enableSSL.ldif':
    source => "puppet:///modules/${module_name}/root/enableSSL.ldif",
    mode   => '0600',
  }

  file { '/root/enableSSL2.ldif':
    source => "puppet:///modules/${module_name}/root/enableSSL2.ldif",
    mode   => '0600',
  }

  file { '/root/enableSSL3.ldif':
    source => "puppet:///modules/${module_name}/root/enableSSL3.ldif",
    mode   => '0600',
  }

  file { '/root/createNCSAldap':
    source => "puppet:///modules/${module_name}/root/createNCSAldap",
    mode   => '0700',
  }

  file { '/root/addRSA.ldif.template':
    source => "puppet:///modules/${module_name}/root/addRSA.ldif.template",
    mode   => '0600',
  }

  file { '/root/createSSL':
    source => "puppet:///modules/${module_name}/root/createSSL",
    mode   => '0700',
  }
  file { '/root/bindings.ldif.template':
    source => "puppet:///modules/${module_name}/root/bindings.ldif.template",
    mode   => '0700',
  }

  file { '/root/ldap-sync.py':
    source => "puppet:///modules/${module_name}/root/ldap-sync.py",
    mode   => '0700',
  }

  exec { 'customize_ldap':
    command     => '/root/createNCSAldap',
    subscribe   => [
  File['/root/enableMemberOf.ldif'],
  File['/root/setToUniqueMember.ldif'],
  File['/root/enableInetUser.ldif'],
  File['/root/ds389setup.inf'],
  File['/root/createNCSAldap'],
    ],
    creates     => '/etc/dirsrv/slapd-ncsa-ldap',
    refreshonly => true,
  }

  exec { 'customize_addRSA':
    command     => '/bin/cat /root/addRSA.ldif.template | /bin/sed -e "s/HOSTNAME/`hostname`/" > /root/addRSA.ldif',
    subscribe   => File['/root/addRSA.ldif.template'],
    creates     => '/root/addRSA.ldif',
    refreshonly => true,
  }

  exec { 'createSSL':
    command     => '/root/createSSL',
    subscribe   => [
        File['/root/createSSL'],
        Exec['customize_ldap'],
    ],
    creates     => '/etc/dirsrv/slapd-ncsa-ldap/cert.req',
    refreshonly => true,
  }
  exec { 'customize_bindings':
    command     => "/bin/cat /root/bindings.ldif.template | /bin/sed -e 's/HOST/${facts['ipaddress']}/' > /root/bindings.ldif",
    subscribe   => File['/root/bindings.ldif.template'],
    creates     => '/root/bindings.ldif',
    refreshonly => true,
  }
  file { '/etc/krb5.keytab':
    mode  => '0640',
    group => 'nobody',
  }

  file { '/root/scripts/monitor_top_connections_current.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_connections_current.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }
  file { '/root/scripts/monitor_top_connections_recent.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_connections_recent.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }
  file { '/root/scripts/monitor_top_requests_current.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_requests_current.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }
  file { '/root/scripts/monitor_top_requests_recent.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_requests_recent.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }
  file { '/root/scripts/monitor_top_authenticators_current.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_authenticators_current.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }
  file { '/root/scripts/monitor_top_authenticated_users_current.sh':
    ensure  => 'file',
    source  => "puppet:///modules/${module_name}/root/scripts/monitor_top_authenticated_users_current.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      File['/root/scripts'],
    ],
  }

}
