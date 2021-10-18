import logging
import sys
import json
import traceback

import ldap
import ldap.modlist
import pprint
from ldap.controls import SimplePagedResultsControl


def sync_ldap(ldap_config):
    master = ldap.initialize(config["master"])
    master.simple_bind_s("", "")

    target = ldap.initialize(config["self"]["url"])
    target.simple_bind_s(config["self"]["user"], config["self"]["password"])

    users = get_users(master)
    groups = get_groups(master)

    #print("Read " + str(len(users))) + " users from master\n"
    #print("Read " + str(len(groups))) + " groups from master\n"

    if "cluster" in ldap_config:
        cluster_details = get_cluster_details(master)
        users, groups = transform_for_cluster(cluster_details, users, groups, ldap_config)

    write_users(target, users)
    write_groups(target, groups)


def get_users(server):
    return paged_query(server, "People", "uid=*")


def get_groups(server):
    return paged_query(server, "Groups", "cn=*")


def get_cluster_details(master):
    return paged_query("objectClass=clusterAttributes")


def transform_for_cluster(cluster_details, users, groups, ldap_config):
    # filter by cluster, key by member
    cluster_name = ldap_config["cluster"]["name"]
    data = []
    for entry in cluster_details:
        entry_cluster = entry["cluster"]
        if entry_cluster == cluster_name:
            member = entry["member"]
            data[member] = entry

    include_non_cluster_groups = ("includeNonClusterGroups" in ldap_config["cluster"])
    include_non_cluster_users = ("includeNonClusterGroups" in ldap_config["cluster"])

    transformed_groups = []
    for group in groups:
        group_cluster = None
        if "cluster" in group:
            group_cluster = group["cluster"]
        if group_cluster == cluster_name or (group_cluster is None and include_non_cluster_groups):
            transformed_groups.append(group)

    transformed_users = []
    for user in users:
        dn = user["dn"]

        group_cluster = None
        if "cluster" in group:
            group_cluster = group["cluster"]
        if group_cluster == cluster_name or (group_cluster is None and include_non_cluster_groups):
            transformed_groups.append(group)

    return users, groups


def write_users(target, users):
    update_all(target, users, get_users(target), "uid", "People")


def write_groups(target, groups):
    update_all(target, groups, get_groups(target), "cn", "Groups")


def update_all(target, new_items, existing_items, id_attr, ou):
    if len(new_items) == 0:
        print("WARNING: new " + ou + " is empty. Ignoring request")
        return

    # first find existing entries that aren't in the new list (delete them)
    existing_ids = get_all_attributes(existing_items, id_attr)
    new_ids = get_all_attributes(new_items, id_attr)

    to_delete = [id for id in existing_ids if id not in new_ids]
    num_to_delete = len(to_delete)

    if num_to_delete > 0 and num_to_delete == len(existing_ids):
        print("WARNING: ignoring request to update " + ou + " with all " + ou + " deleted")
        return

    # delete the items to remove
    for id_to_delete in to_delete:
        target.delete(id_attr + "=" + id_to_delete + ",ou=" + ou + ",dc=ncsa,dc=illinois,dc=edu")
        #print "deleting " + id_to_delete + " \n"
    if len(to_delete) > 0:
        print "DEBUG - deleted " + str(len(to_delete)) + " entries from " + ou
        sys.stdout.flush()

    # then for each entry in the new list
    updated = 0
    added = 0
    for new_entry in new_items:
        id = new_entry[id_attr][0]
        dn = id_attr + "=" + id + ",ou=" + ou + ",dc=ncsa,dc=illinois,dc=edu"
        # see if it exists, if so, update
        if id in existing_ids:
            updated = updated + 1
            try:
                old_entry = find_old_entry(target, dn)[0][1]
                modlist = ldap.modlist.modifyModlist(old_entry, new_entry)
                #print "updating " + dn + "\n"
                target.modify_s(dn, modlist)
            except ldap.LDAPError as e:
                print "WARN - failure updating: deleting and recreating"
                print modlist
                print old_entry
                print new_entry
                target.delete(id_attr + "=" + id + ",ou=" + ou + ",dc=ncsa,dc=illinois,dc=edu")
                modlist = ldap.modlist.addModlist(new_entry)
                target.add_s(dn, modlist)


        else:
            added = added + 1
            try :
                #print "adding " + dn + "\n"
                modlist = ldap.modlist.addModlist(new_entry)
                target.add_s(dn, modlist)
            except ldap.LDAPError as e:
                try:
                    print "WARN - failure adding " + dn + "Deleting and re-creating \n"
                    target.delete(id_attr + "=" + id + ",ou=" + ou + ",dc=ncsa,dc=illinois,dc=edu")
                    modlist = ldap.modlist.addModlist(new_entry)
                    target.add_s(dn, modlist)
                except ldap.LDAPError as e:
                    print "ERROR - failure adding"
                    sys.stdout.flush()


    if updated > 0:
        print "DEBUG - synced " + str(updated) + " entries in " + ou
        sys.stdout.flush()
    if added > 0:
        print "DEBUG - added " + str(added) + " entries in " + ou
        sys.stdout.flush()



def get_all_attributes(entries, attr):
    return [e[attr][0] for e in entries]


def find_old_entry(target, dn):
    parts = dn.split(",")
    return target.search_s("dc=ncsa,dc=illinois,dc=edu", ldap.SCOPE_SUBTREE, parts[0])


def paged_query(connection, ou, query):
    page_size = 500
    paging_control_request = create_paging_control(page_size)
    results = []
    while True:
        try:
            query_result_id = connection.search_ext("ou=" + ou + ",dc=ncsa,dc=illinois,dc=edu", ldap.SCOPE_SUBTREE,
                                                    query,
                                                    serverctrls=[paging_control_request])

            result_type, result_data, result_msg_id, server_controls = connection.result3(query_result_id)

            for dn, attrs in result_data:
                results.append(attrs)

            paging_control = get_paging_control(server_controls)
            if not paging_control:
                print >> sys.stderr, 'Warning: Server ignores RFC 2696 control.'
                break

            cookie = set_cookie(paging_control_request, paging_control)
            if not cookie:
                break
        except ldap.LDAPError as e:
            logging.error(traceback.format_exc())

    return results


def create_paging_control(page_size):
    return SimplePagedResultsControl(True, size=page_size, cookie='')


def get_paging_control(server_controls):
    return [c for c in server_controls
            if c.controlType == SimplePagedResultsControl.controlType]


def set_cookie(lc_object, pctrls):
    """Push latest cookie back into the page control."""
    cookie = pctrls[0].cookie
    lc_object.cookie = cookie
    return cookie


def loadCloneConfig():
    with open('/root/ldap.RootDNPwd', 'r') as myfile:
        password = myfile.read().replace('\n', '')

    config = {
        "master": "ldaps://ldap.ncsa.illinois.edu",
        "self": {
            "url": "ldap://localhost",
            "user": "cn=Directory Manager",
            "password": password
        }
    }
    return config


if __name__ == "__main__":
    if (len(sys.argv)) <= 1:
        print("Usage: ldap-sync.py [--clone-master] [config-file]")
        exit(1)

    if "--clone-master" in sys.argv:
        config = loadCloneConfig()
    else:
        with open(sys.argv[1]) as f:
            config = json.load(f)

    print "DEBUG - sync starting"
    sys.stdout.flush()
    sync_ldap(config)
    print "DEBUG - sync complete"
    sys.stdout.flush()

