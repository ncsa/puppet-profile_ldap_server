# @summary Install HARDCODED hosts.allow and deny files
#
# @example
#   include profile_ldap_server::tcpwrappers
class profile_ldap_server::tcpwrappers {

  # WARNING - DEPRECATED
  # TCPWRAPPERS WAS REMOVED IN RHEL8
  # safe to remove this file entirely once all ldap servers are rebuilt on RHEL8

  # NOTE:  This class' configuration of hosts.allow and hosts.deny could conflict with other
  #       definitions for them in other classes.
  file { '/etc/hosts.allow':
    source => "puppet:///modules/${module_name}/etc/hosts.allow",
    mode   => '0644',
  }

  file { '/etc/hosts.deny':
    source => "puppet:///modules/${module_name}/etc/hosts.deny",
    mode   => '0644',
  }

}
