#Class to set, reset and manage the default mysql root password.

#Class originally by Daneyon Hansen and Jimdo
#Modified 12/21/2012 by Justice London

#Options:
#[root_password] The ROOT password for mysql to use for this server (and technically all others).
#[old_root_password] If you are changing the root password for the server(s) you need to insert the old
#root password so as to allow for login to mysqladmin
#[mysql_user] If you are changing the galera SST user this is the field to set
#[mysql_password] The mysql password for the wsrep SST user.

class galera::galeraroot (
  $etc_root_password = $galera::etc_root_password, 
  $mysql_user        = $galera::mysql_user,
  $mysql_password    = $galera::mysql_password,
  $old_root_password = $galera::old_root_password,
  $root_password     = $galera::root_password,
)
{
  # manage root password if it is set
  if $root_password != 'UNSET' {
    case $old_root_password {
      '':      { $old_pw='' }
      default: { $old_pw="-p${old_root_password}" }
    }

    exec { 'set_mysql_rootpw':
      command   => "mysqladmin -u root ${old_pw} password ${root_password}",
      logoutput => true,
      unless    => "mysqladmin -u root -p${root_password} status > /dev/null",
      path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
      require   => Service['mysql'],
      tries     => 2,
      try_sleep => 5,
   }

    file { '/root/.my.cnf':
      content => template('galera/my.cnf.pass.erb'),
      require => Exec['set_mysql_rootpw'],
    }

    if $etc_root_password {
      file{ '/etc/my.cnf':
        content => template('galera/my.cnf.pass.erb'),
        require => Exec['set_mysql_rootpw'],
      }
    }

  }

    #On first run and on wsrep config modification, run an update to the wsrep user/password
    exec { 'set-mysql-password' :
      unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
      command     => "/usr/bin/mysql -uroot -p${root_password} -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
      require     => Service["mysql"],
      subscribe   => Service["mysql"],
      refreshonly => true,
      tries 	  => 2,
      try_sleep   => 5,
    }

}
