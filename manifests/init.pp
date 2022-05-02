# @summary Configure an LDAP server for use at NCSA
#
# @example
#   include profile_ldap_server
class profile_ldap_server {

  include epel
  include profile_ldap_server::crontab
  include profile_ldap_server::firewall
  include profile_ldap_server::services

  # tcpwrappers was removed in RHEL8
  $os_family = $facts['os']['family']
  $os_rel_major = Integer( $facts['os']['release']['major'] )
  if $os_family == 'RedHat' and $os_rel_major < 8 {
    include ::profile_ldap_server::tcpwrappers
  }

  Class['epel']
    -> Class['profile_ldap_server::services']

}
