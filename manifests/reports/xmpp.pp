# A report plugin to send XMPP to people when nodes fail.
# See http://www.kartar.net/2011/06/puppet-xmpp/ and
# https://github.com/barn/puppet-xmpp
#
class puppet::reports::xmppreport {

  Package{ provider => 'gem', ensure => present }

  package{
    'xmpp4r':;
    'json':;
    'httparty':;
  }

  # This is a little bit dirty, as it just throws it straight in the
  # rubylib, but it's better than messing with libdir on the master.
  # See https://projects.puppetlabs.com/issues/4345 for mild
  # discussion.
  file{
    '/usr/lib/ruby/1.8/puppet/reports/xmpp.rb':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/puppet/xmpp.rb',
        notify => Class['puppet::server'];
    '/etc/puppet/xmpp.yaml':
        ensure => present,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0440',
        source => 'puppet:///modules/puppet/xmpp.yaml',
        notify => Class['puppet::server'];
  }

}
