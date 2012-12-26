This is a good start to play around with the galera multi-master mysql synchronous replication (http://www.codership.com/products/mysql_galera)

#HOWTO:

 * install vagrant: http://vagrantup.com/
 * get debian squeeze basebox (http://vagrantbox.es) or build your own (https://github.com/jedi4ever/veewee)
 * type "vagrant up"
 * watch 3 nodes to get provisioned
 * play around (add a database and data, chaos-monkey nodes etc.)


#WARNING

Change the mysql root password in production and limit access to galera cluster members!

Additionally, if you are using this module having never implemented Galera before you need to:
- Disable SELinux (Sorry. Eventually I might add support for this, but right now Galera does not like it.
- Open firewall ports: 3306, 4567, 4568, 4444

#TODO

 * put a load balancer in front of the cluster

#Nodes
    $cluster_name = 'my_galera_dev'

    node /^galera/ {

    #This defines the node using the node FQDN as the 'name'
    #Specify the cluster to use with cluster_name
    @@galera::galeranode { $fqdn:
      cluster_name => "${cluster_name}", }

    #Realize the galera nodes for cluster 'galera'
    class {'galera': 
      cluster_name => "${cluster_name}", }  
    }  

