# == Class: puppet::agent
#
# Install, configure, and run a puppet agent instance.
#
# == Parameters
#
# [*server*]
#   The puppet server to use for fetching catalogs. Required.
# [*ca_server*]
#   The puppet server to use for certificate requests and similar actions.
#   Default: puppet::agent::server
# [*report_server*]
#   The puppet server to send reports.
#   Default: puppet::agent::server
# [*manage_repos*]
#   Whether to manage Puppet Labs APT or YUM package repos.
#   Default: true
# [*method*]
#   The mechanism for performing puppet runs.
#   Supported methods: [cron, service]
#   Default: cron
# [*monitor_service*]
#   Whether or not to monitor the puppet service.
#   Should not be mixed when method is cron.
#   Default: false
# [*cron_interval*]
#   How often puppet should run via cron.
#   Default: 3
# [*environment*]
#   What environment the agent should be part of.
#   Default: production
#
# == Example:
#
#   class { 'puppet::agent':
#     server        => 'puppet.example.com',
#     report_server => 'puppet_reports.example.com',
#     method        => 'service',
#  }
#
class puppet::agent(
  $server          = hiera('puppet::agent::server', 'puppet'),
  $ca_server       = hiera('puppet::agent::server', 'puppet'),
  $report_server   = hiera('puppet::agent::server', 'puppet'),
  $manage_repos    = true,
  $method          = 'cron',
  $monitor_service = false,
  $cron_interval   = 3,
  $environment     = 'production'
) {

  include puppet

  if $manage_repos {
    require puppet::package
  }

  if $monitor_service {
    class { '::puppet::agent::monitor': enable => true }
  } else {
    class { '::puppet::agent::monitor': enable => false }
  }

  case $method {
    cron: { 
      class { 'puppet::agent::cron': interval => $cron_interval }
    }
    service: { 
      class { 'puppet::agent::service': }
    }
    default: {
      notify { "Agent run method \"${method}\" is not supported by ${module_name}, defaulting to cron": loglevel => warning }
      class { 'puppet::agent::cron': interval => $cron_interval }
    }
  }

  # ----
  # puppet.conf management
  concat::fragment { 'puppet.conf-agent':
    order   => '00',
    target  => $puppet::params::puppet_conf,
    content => template("puppet/puppet.conf/agent.erb");
  }

}
