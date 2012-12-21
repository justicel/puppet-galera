#Defines a galera group node.
#Requires a storeconfigs backend (puppetdb, etc.) to be setup
#Options:
#[cluster_name] The name of the galera group you are going to add this node to.
#[ipaddress] The IP address to use to actually connect to the server. This could ALSO be a separate
#hostname. By default it's the primary IP on the system/server.
#[order] The default order to use. Defaults to 11, but this will likely need to be changed for additional groups.
#[galeraconfig] You probably shouldn't touch this.

define galera::galeranode (
  $cluster_name = $galera::params::cluster_name,
  $order        = '11',
  $ipaddress    = $::ipaddress,
  $galeraconfig = $galera::params::galeraconfig,
) 
{

  #Very basic node definition here
  concat::fragment { "${cluster_name}_galera_node_${name}":
    order   => $order,
    target  => $galeraconfig,
    content => "gcomm://${ipaddress}:4567,",
  }
}
