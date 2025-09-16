# @summary Configure firewall rules for LDAP services
#
# @param clientsubnets
#   List of subnets that are allowed to connect to LDAP port 636
#
# @param replsubnets
#   List of subnets that are allowed to connect to LDAP port 389
#
# @param badsubnets
#   List of subnets that are probitited to connect to LDAP services
#
# @example
#   include profile_ldap_server::firewall
class profile_ldap_server::firewall (
  Hash $clientsubnets,
  Hash $replsubnets,
  Hash $badsubnets,
) {

  $clientsubnets.each | $location, $source_cidr |
  {
    firewall { "250 ALLOW LDAPS FROM ${location}":
      proto  => tcp,
      dport  => '636',
      source => $source_cidr,
      action => accept,
    }
  }

  $replsubnets.each | $location, $source_cidr |
  {
    firewall { "250 ALLOW LDAP FROM ${location}":
      proto  => tcp,
      dport  => '389',
      source => $source_cidr,
      action => accept,
    }
  }

  $badsubnets.each | $location, $source_cidr |
  {
    firewall { "200 BLOCK BAD ACTORS FROM ${location}":
      proto  => 'all',
      source => $source_cidr,
      action => 'drop',
    }
  }

}
