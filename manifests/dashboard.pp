# Class: puppet::dashboard
#
# This class installs and configures parameters for Puppet Dashboard
#
# Parameters:
# * site: fqdn for the dashboard site
# * db_user: the username for the database
# * db_pw: the password for the database
# * allowip: space seperated list of ip addresses to allow report uploads
#
# Actions:
#   Install puppet-dashboard packages
#   Write the database.yml
#   Install the apache vhost
#   Installs logrotate
#
# Requires:
#
# Sample Usage:
#   class { puppet::dashboard: site => 'dashboard.xyz.net; }
#
class puppet::dashboard (
    $site      = "dashboard.${domain}",
    $db_user   = "dashboard",
    $db_pw     = 'ch@ng3me',
    $allowip   = '',
    $appserver = 'passenger'
  ) {

  $allow_all_ips = "${allowip} ${ipaddress}"

  include ruby::dev

  $dashboard_site = $site

  case $appserver {
    'passenger': {
      include ::passenger
      include passenger::params
      $passenger_version=$passenger::params::version
      $gem_path=$passenger::params::gem_path

#      apache::vhost { $dashboard_site:
#        port     => '80',
#        priority => '50',
#        docroot  => '/usr/share/puppet-dashboard/public',
#        template => 'puppet/vhost/apache/passenger-dashboard.conf.erb',
#      }

    }
    'unicorn': {
      unicorn::app {
        $dashboard_site:
          approot                  => '/usr/share/puppet-dashboard',
          config_file              => '/usr/share/puppet-dashboard/config/unicorn.config.rb',
          unicorn_pidfile          => '/var/run/puppet/puppet_dashboard_unicorn.pid',
          unicorn_socket           => '/var/run/puppet/puppet_dashboard_unicorn.sock',
          rack_file                => 'puppet:///modules/unicorn/config.ru',
          unicorn_worker_processes => '2',
          unicorn_user             => 'www-data',
          unicorn_group            => 'www-data',
          log_stds                 => true,
          stdlog_path              => '/var/log/puppet-dashboard',
      }
      nginx::unicorn {
        'dashboard.puppetlabs.com':
          priority       => 50,
          unicorn_socket => '/var/run/puppet/puppet_dashboard_unicorn.sock',
          path           => '/usr/share/puppet-dashboard',
          auth           =>  { 'auth' => true, 'auth_file' => '/etc/nginx/htpasswd', 'allowfrom' => $allowip },
          ssl            => true,
          sslonly        => true,
          isdefaultvhost => true, # default for SSL.
      }
      #if ! defined(Class["apache"] { include apache::remove }
    }
  }

  package { 'puppet-dashboard':
    ensure => present,
  }

  mysql::db { "dashboard_production":
    db_user => $db_user,
    db_pw   => $db_pw;
  }

  file { '/etc/puppet-dashboard/database.yml':
    ensure  => present,
    content => template('puppet/dashboard/database.yml.erb'),
    require => Package['puppet-dashboard'],
  }

  file{ '/usr/share/puppet-dashboard/config/settings.yml':
    mode    => '0444',
    owner   => 'www-data',
    group   => 'www-data',
    content => "---\ntime_zone: 'Pacific Time (US & Canada)'",
    notify  => Unicorn::App[$dashboard_site],
  }

  file { [ '/usr/share/puppet-dashboard/public', '/usr/share/puppet-dashboard/public/stylesheets', '/usr/share/puppet-dashboard/public/javascript' ]:
    mode => 0755,
    owner => 'www-data',
    group => 'www-data',
    require => Package['puppet-dashboard'],
  }

}

