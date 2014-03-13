class puppet::server::standalone (
  $enabled = true
) {

  include puppet
  include puppet::server


  file { '/etc/init.d/puppetmaster':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/puppet/puppetmaster.init',
    require => Class['::puppet::server'],
  }

  service { $puppet::params::master_service:
    ensure    => $enabled ? {true => running, false => stopped},
    enable    => $enabled,
    hasstatus => true,
    require   => File['/etc/init.d/puppetmaster'],
  }

}
