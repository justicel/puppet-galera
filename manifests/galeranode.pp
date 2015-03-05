#Defines a galera group node.
#Requires a storeconfigs backend (puppetdb, etc.) to be setup
#Options:
# [*cluster_name*] The name of the galera group you are going to add this node to.
# [*node_ipaddress*] The IP address to use to actually connect to the server. This could ALSO be a separate
#   hostname. By default it's the primary IP on the system/server.
# [*galeraconfig*] You probably shouldn't touch this.

define galera::galeranode (
  $cluster_name   = $::galera::params::cluster_name,
  $node_ipaddress = $::ipaddress,
) {
  include ::galera

  #Very basic node definition here
  concat::fragment { "${cluster_name}_galera_node_${name}":
    order   => "11-${cluster_name}-${node_ipaddress}",
    target  => $::galera::galeraconfig,
    content => "gcomm://${node_ipaddress}:4567,",
  }
}
