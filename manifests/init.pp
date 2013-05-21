# Install and configure MCollective servers (managed nodes) and client
# (management node)
# Set MCollective with the OpenSSL based Security Plugin
#
# The Marionette Collective AKA MCollective is a framework to build
# server orchestration or parallel job execution systems.

class mcollective ( $nocnode = 'el6' ) {

    include yum
    include yum::kermit

    package { 'mcollective-common' :
        ensure   => present,
        require  => Yumrepo[ 'kermit-custom', 'kermit-thirdpart' ],
    }

    package { 'mcollective' :
        ensure   => installed,
        require  => Package[ 'mcollective-common' ],
    }

    package { 'mcollective-client' :
        ensure  => $::hostname ? {
            $nocnode => present,
            default  => absent,
        },
        require => Package[ 'mcollective-common' ],
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
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/etc/mcollective/facts.yaml' :
        owner    => 'root',
        group    => 'root',
        mode     => '0400',
        loglevel => debug,  # this is needed to avoid it being logged
                            # and reported on every run
        # avoid including highly-dynamic facts
        # as they will cause unnecessary template writes
        #content => inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime|timestamp|memory|free|swap)/ }.to_yaml %>')
        content  => inline_template('<%= Hash[scope.to_hash.reject { |k,v| k.to_s =~ /(uptime|timestamp|memory|free|swap)/ }.sort].to_yaml %>')
    }

    file { '/etc/mcollective/server.cfg' :
        ensure       => present,
        require      => Package[ 'mcollective-common' ],
        owner        => 'root',
        group        => 'root',
        mode         => '0640',
        source       => 'puppet:///modules/mcollective/serverprod.cfg',
        #source      => $hostname ? {
        #    'el4'   => 'puppet:///modules/mcollective/serverqa.cfg',
        #    default => 'puppet:///modules/mcollective/serverprod.cfg',
        #},
    }

    file { '/etc/mcollective/client.cfg' :
        ensure  => $::hostname ? {
            $nocnode => present,
            default  => absent,
        },
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/mcollective/client.cfg',
        require => Package[ 'mcollective-common' ],
    }

    file { '/etc/mcollective/ssl/server-private.pem' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        source  => 'puppet:///public/mcollective/server-private.pem',
        require => Package[ 'mcollective-common' ],
    }

    file { '/etc/mcollective/ssl/server-public.pem' :
        ensure  => present,
        require => Package[ 'mcollective-common' ],
        owner   => 'root',
        group   => 'root',
        mode    => $::hostname ? {
            $nocnode => '0644',
            default  => '0640',
        },
        source  => 'puppet:///public/mcollective/server-public.pem',
    }

    file { '/etc/mcollective/ssl/clients/noc-public.pem' :
        ensure  => present,
        require => [  Package[ 'mcollective-common' ],
                      File[ '/etc/mcollective/ssl/clients' ] ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///public/mcollective/noc-public.pem',
    }

    if $::hostname == $nocnode {
        file { '/etc/mcollective/ssl/clients/noc-private.pem' :
            ensure  => present 
            require => [  Package[ 'mcollective-common' ],
                          File[ '/etc/mcollective/ssl/clients' ] ],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///private/mcollective/noc-private.pem',
        }
    }

    service { 'mcollective' :
        ensure  => running,
        require => [  Package[ 'mcollective' ],
                      File[ '/etc/mcollective/server.cfg',
                            '/etc/mcollective/ssl/server-public.pem',
                            '/etc/mcollective/ssl/server-private.pem',
                            '/etc/mcollective/ssl/clients/noc-public.pem'], ],
        enable  => true,
    }

}
