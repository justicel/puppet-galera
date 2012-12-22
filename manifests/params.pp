#Basic definitions for galera parameters
#You should probably set in your master configuration the default root and mysql passwords to something
#more sensible.

class galera::params {
  $cluster_name      = 'galera'
  $mysql_user        = 'wsrep_sst'
  $mysql_password    = 'G@l3RaL0g'
  $root_password     = 'Ch@ng3Th1s'
  $old_root_password = ''
  $etc_root_password = false
  $enabled           = true

  #Set the repository information for either rpm or deb
  case $osfamily {
    Redhat: {
      package { 'percona-release':
        ensure   => present,
        source   => 'http://www.percona.com/redir/downloads/percona-release/percona-release-0.0-1.x86_64.rpm',
        provider => 'rpm',
      }

      $configfile    = '/etc/my.cnf'
      $galeraconfig  = '/etc/mysql/conf.d/wsrep.cnf'
      $galerapackage = 'Percona-XtraDB-Cluster-server'
      $galeralib     = '/usr/lib64/libgalera_smm.so'
    }
    Debian: {
      #This requires puppet-apt. If you don't have it a) You need it b) It's extremely useful
      apt::source { 'percona_xtradb':
        location    => 'http://repo.percona.com/apt',
        repos       => 'main',
        key         => '1C4CBDCDCD2EFD2A',
        key_server  => 'keys.gnupg.net',
        include_src => true,
      }

      #Modified debian-start to disable mysqlcheck
      file { '/etc/mysql/debian-start':
        ensure  => present,
        source  => 'puppet:///modules/galera/debian-start',
        mode    => '0755',
        require => File['/etc/mysql'],
      }

      $configfile    = '/etc/mysql/my.cnf'
      $galeraconfig  = '/etc/mysql/conf.d/wsrep.cnf'
      $galerapackage = 'percona-xtradb-cluster-server-5.5'
      $galeralib     = '/usr/lib/libgalera_smm.so'
    }
  }

}
