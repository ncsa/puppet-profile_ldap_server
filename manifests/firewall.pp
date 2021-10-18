# @summary Configure firewall rules for LDAP services
#
# @param allowsubnets
#   List of subnets that are allowed to connect to LDAP services
#
# @param badsubnets
#   List of subnets that are probitited to connect to LDAP services
#
# @example
#   include profile_ldap_server::firewall
class profile_ldap_server::firewall (
  Hash $allowsubnets,
  Hash $badsubnets,
) {

  $allowsubnets.each | $location, $source_cidr |
  {
    firewall { "1000 ALLOW LDAP FROM ${location}":
      proto  => tcp,
      dport  => '636',
      source => $source_cidr,
      action => accept,
    }
  }

  $badsubnets.each | $location, $source_cidr |
  {
    firewall { "1100 BLOCK BAD ACTORS FROM ${location}":
      proto  => 'all',
      source => $source_cidr,
      action => 'drop',
    }
  }

}
