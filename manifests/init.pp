#Galera puppet module originally by Jimdo.
#Re-based by Justice London <jlondon@syrussystems.com>
#Source at: https://github.com/justicel/puppet-galera
#Contact Justice for support (or fork this, on github!)
#Uses Percona XtraDB distribution of Galera which provides a stable Galera base but also xtradb engine

#Params are mostly included as a starting point for a build.
#Root password and similar should be changed from defaults although they are more complex
#than other 'default' passwords at least.
class galera (
  $version                   = '5.7',
  $cluster_name              = $::galera::params::cluster_name,
  $mysql_user                = $::galera::params::mysql_user,
  $mysql_password            = $::galera::params::mysql_password,
  $root_password             = $::galera::params::root_password,
  $enabled                   = $::galera::params::enabled,
  $galeraconfig              = $::galera::params::galeraconfig,
  $clusterconfig             = $::galera::params::clusterconfig,
  $mysqlconfig               = 'galera/my.cnf.erb',
  $configfile                = $::galera::params::configfile,
  $old_root_password         = $::galera::params::old_root_password,
  $etc_root_password         = $::galera::params::etc_root_password,
  $wsrep_slave_threads       = '4',
  $custom_innodb_buffer_pool = undef,
  $provider_options          = {},
) inherits ::galera::params {
  #Include root password settings as needed
  include ::galera::galeraroot

  #Check if the main server package (and dependent packages) are installed
  ensure_packages(["${::galera::params::compatpackage}${version}", 'socat' ], {
    ensure => present,
  })
  ensure_packages(["${::galera::params::galerapackage}${version}"], {
    ensure  => present,
    require => [
      Package["${::galera::params::compatpackage}${version}"],
      Package['socat'],
      Concat_file[$galeraconfig],
      Concat_file[$clusterconfig],
    ],
    notify => Exec['mysql_install_db'],
  })

  #Just to be safe, we run install command for mysql on package install
  exec { 'mysql_install_db':
    path        => ['/usr/bin/:/usr/sbin/:/sbin/:/bin/'],
    creates     => '/var/lib/mysql/mysql/user.frm',
    refreshonly => true,
    require     => [File[$configfile], Concat_file[$galeraconfig], Concat_file[$clusterconfig]],
    before      => [
      Service['mysql-galera'],
      Exec['galera-reload'],
      Exec['galera-restart'],
    ],
  }

  #Define a basic mysql-galera service
  $service_ensure = $enabled ? {
    false   => 'stopped',
    default => 'running',
  }
  service { 'mysql-galera':
    ensure    => $service_ensure,
    name      => 'mysql',
    enable    => $enabled,
    hasstatus => false,
    require   => [
      File[$configfile, '/var/run/mysqld'],
      Concat_file[$galeraconfig],
      Concat_file[$clusterconfig],
      Package["${::galera::params::galerapackage}${version}"],
    ],
  }

  #Custom exec to only reload mysql on config changes
  exec { 'galera-reload':
    command     => 'service mysql reload',
    path        => ['/usr/bin:/usr/sbin:/sbin:/bin'],
    refreshonly => true,
    require     => [
      Package["${::galera::params::galerapackage}${version}"],
      Service['mysql'],
    ],
  }

  exec { 'galera-restart':
    command     => 'service mysql restart',
    path        => ['/usr/bin:/usr/sbin:/sbin:/bin'],
    logoutput   => on_failure,
    refreshonly => true,
  }

  #Default mysql config file
  file { $configfile:
    ensure  => present,
    content => template($mysqlconfig),
    require => Package["${::galera::params::compatpackage}${version}"],
  }

  #Build  galera config using puppet-concat
  concat { $galeraconfig:
    owner => '0',
    group => '0',
    mode  => '0644',
  }
  concat::fragment { 'galerabody':
    target  => $galeraconfig,
    order   => '01',
    content => "#This file managed by Puppet\n",
  }
  #The main config body as defined by template and concat.
  concat::fragment { "${cluster_name}_galera_body":
    order   => '02',
    target  => $galeraconfig,
    content => template('galera/wsrep.cnf.erb'),
  }

  concat { $clusterconfig:
    owner => '0',
    group => '0',
    mode  => '0644',
  }
  concat::fragment { 'clusterconfig_body':
    target  => $clusterconfig,
    order   => '01',
    content => "#This file managed by Puppet\n",
  }
  concat::fragment { "${cluster_name}_cluster_body":
    order => '02',
    target => $clusterconfig,
    content => template('galera/cluster.cnf.erb'),
  }
  #Realize cluster members as wsrep_url entries
  Galera::Galeranode <<| cluster_name == $cluster_name |>>

  concat::fragment { "${cluster_name}_cluster_address":
    order   => '10',
    target  => $clusterconfig,
    content => 'wsrep_cluster_address=gcomm://',
  }
    
  #Necessary base folders for all configs
  file { ['/etc/mysql','/etc/mysql/conf.d', '/var/run/mysqld']:
    ensure  => directory,
    mode    => '0755',
    owner   => $::galera::params::mysqlowner,
    group   => $::galera::params::mysqlgroup,
    before  => File[$configfile],
    require => Package["${::galera::params::compatpackage}${version}"],
  }
}
