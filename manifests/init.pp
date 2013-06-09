# Install and configure MCollective servers (managed nodes)
# Set MCollective with the OpenSSL based Security Plugin
#
# The Marionette Collective AKA MCollective is a framework to build
# server orchestration or parallel job execution systems.

class mcollective {

    include mcollective::params

    include yum
    include kermit::yum

    # Used with factsource facter plugin
    #package { 'mcollective-plugins-facter_facts' :
    #    ensure   => present,
    #    require  => Yumrepo[ 'kermit-custom' ],
    #}

    package { 'mcollective-common' :
        ensure   => present,
        require  => Yumrepo[ 'kermit-thirdpart' ],
    }

    package { 'mcollective' :
        ensure   => installed,
        require  => Package[ 'mcollective-common' ],
    }

    file { '/etc/mcollective/ssl' :
        ensure  => 'directory',
        require => Package[ 'mcollective-common' ],
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/etc/mcollective/ssl/clients' :
        ensure  => 'directory',
        require => File[ '/etc/mcollective/ssl' ],
        recurse => true,
        purge   => true,
        force   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///public/mcollective/clients',
        notify  => Service["mcollective"],
    }

    # Used with factsource yaml plugin (need to restart mcollective for changed)
    file { '/etc/mcollective/facts.yaml' :
        owner    => 'root',
        group    => 'root',
        mode     => '0400',
        loglevel => debug,  # this is needed to avoid it being logged
                            # and reported on every run
        # avoid including highly-dynamic facts
        # as they will cause unnecessary template writes
        #content => inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime|timestamp|memory|free|swap)/ }.to_yaml %>')
        content  => inline_template('<%= Hash[scope.to_hash.reject { |k,v| k.to_s =~ /(uptime|timestamp|memory|free|swap)/ }.sort].to_yaml %>'),
        notify => Service["mcollective"],
    }

    file { '/etc/mcollective/server.cfg' :
        ensure       => present,
        require      => Package[ 'mcollective-common' ],
        owner        => 'root',
        group        => 'root',
        mode         => '0640',
        content      => template( 'mcollective/server.cfg' ),
        #source      => $::fqdn ? {
        #    'el4'   => 'puppet:///modules/mcollective/serverqa.cfg',
        #    default => 'puppet:///modules/mcollective/serverprod.cfg',
        #},
        notify => Service["mcollective"],
    }

    file { '/etc/mcollective/ssl/server-private.pem' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => 'puppet:///public/mcollective/server-private.pem',
        require => Package[ 'mcollective-common' ],
        notify => Service["mcollective"],
    }

    file { '/etc/mcollective/ssl/server-public.pem' :
        ensure  => present,
        require => Package[ 'mcollective-common' ],
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => 'puppet:///public/mcollective/server-public.pem',
        notify => Service["mcollective"],
    }

    service { 'mcollective' :
        ensure  => running,
        require => [  Package[ 'mcollective' ],
                      File[ '/etc/mcollective/server.cfg',
                            '/etc/mcollective/ssl/server-public.pem',
                            '/etc/mcollective/ssl/server-private.pem',
                            '/etc/mcollective/ssl/clients'], ],
        enable  => true,
    }

}
