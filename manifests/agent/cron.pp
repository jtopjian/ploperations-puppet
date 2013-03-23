class puppet::agent::cron (
  $enable = true,
  $interval = 3
) {
  include puppet::params

  if ($enable == true) {
    $ensure = present
  } else {
    $ensure = absent
  }

  cron { "puppet agent":
    command => "${puppet::params::puppet_cmd} agent --confdir ${puppet::params::puppet_confdir} --onetime --no-daemonize >/dev/null",
    minute  => interval($interval, 60),
    ensure  => $ensure,
  }

}
