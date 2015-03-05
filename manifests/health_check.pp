#
# class galera::health_check provides in-depth monitoring of a MySQL Galera Node. 
# The class is meant to be used in conjunction with HAProxy.
# The class  has only been tested on Ubuntu 12.04 and HAProxy 1.4.18-0ubuntu1
#
# Requires augeas puppet module
#
# Here is an example HAProxy configuration that implements Galera health checking
#listen galera 192.168.220.40:3306
#  balance  leastconn
#  mode  tcp
#  option  tcpka
#  option  httpchk
#  server  control01 192.168.220.41:3306 check port 9200 inter 2000 rise 2 fall 5
#  server  control02 192.168.220.42:3306 check port 9200 inter 2000 rise 2 fall 5
#  server  control03 192.168.220.43:3306 check port 9200 inter 2000 rise 2 fall 5
#
# Example Usage:
#
# class {'galera::health_check': }
#
class galera::health_check(
  $enabled             = true,
  $mysql_host          = 'localhost',
  $mysqlchk_user       = 'clustercheckuser',
  $mysqlchk_password   = 'clustercheckpassword',
  $clustercheck_script = '/usr/bin/clustercheck',
  $clustercheck_xinetd = 'mysqlchk',
  $check_port          = '9200',
) {
  include ::galera::params

  #Xinetd service define and start
  $service_ensure = $enabled ? {
    false   => 'no',
    default => 'yes',
  }

  #Define the cluster check in xinetd
  xinetd::service { $clustercheck_xinetd:
    disable                 => $service_ensure,
    port                    => $check_port,
    server                  => $clustercheck_script,
    server_args             => "${mysqlchk_user} ${mysqlchk_password}",
    flags                   => 'REUSE',
    per_source              => 'UNLIMITED',
    service_type            => 'UNLISTED',
    log_on_success          => '',
    log_on_success_operator => '=',
    log_on_failure          => 'HOST',
    log_on_failure_operator => '=',
  }

  # Manage mysqlchk service in /etc/services
  augeas { 'mysqlchk':
    context => '/files/etc/services',
    changes => [
      'ins service-name after service-name[last()]',
      'set service-name[last()] mysqlchk',
      "set service-name[. = 'mysqlchk']/port ${check_port}",
      "set service-name[. = 'mysqlchk']/protocol tcp",
    ],
    onlyif  => "match service-name[. = 'mysqlchk'] size == 0",
    require => Xinetd::Service[$clustercheck_xinetd],
  }

  # Create a user for script to use for checking MySQL health status.
  mysql_user { "${mysqlchk_user}@${mysql_host}":
    ensure        => present,
    password_hash => mysql_password($mysqlchk_password),
  }
  mysql_grant { "${mysqlchk_user}@${mysql_host}/*.*":
    ensure     => present,
    options    => ['GRANT'],
    privileges => ['PROCESS'],
    table      => '*.*',
    user       => "${mysqlchk_user}@${mysql_host}",
  }
}
