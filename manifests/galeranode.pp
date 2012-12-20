#Defines a galera group node.
#Requires a storeconfigs backend (puppetdb, etc.) to be setup
#Options:
#[hostname] This specifies the hostname to use for the defined node. By default the fqdn/hostname of
#the system.
#[ipaddress] The IP address to use to actually connect to the server. This could ALSO be a separate
#hostname. By default it's the primary IP on the system/server.
#[order] The default order to use. Defaults to 11, but this will need to be changed for additional groups.
#[configfile] You probably shouldn't touch this.

define galera::galeranode (
  $cluster_name = $galera::params::cluster_name,
  $order        = '11',
  $hostname     = $::fqdn,
  $ipaddress    = $::ipaddress,
  $galeraconfig = $galera::params::galeraconfig,
) {

  #Very basic node definition here
  concat::fragment { "${cluster_name}_galera_node_${name}":
    order   => $order,
    target  => $galeraconfig,
    content => "gcomm://${ipaddress}:4567,",
  }
}

