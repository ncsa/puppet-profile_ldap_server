# @summary Configure an LDAP server for use at NCSA
#
# @example
#   include profile_ldap_server
class profile_ldap_server {

  include profile_ldap_server::crontab
  include profile_ldap_server::firewall
  include profile_ldap_server::services

}
