# Install and configure MCollective servers (managed nodes) and client
# (management node)
# Set MCollective with the OpenSSL based Security Plugin
#
# The Marionette Collective AKA MCollective is a framework to build
# server orchestration or parallel job execution systems.

class mcollective ( $nocnode = 'el6.labolinux.fr' ) {

    include yum
    include yum::kermit

    # Used with factsource facter plugin
    #package { 'mcollective-plugins-facter_facts' :
    #    ensure   => present,
    #    require  => Yumrepo[ 'kermit-custom' ],
    #}

    package { 'mcollective-common' :
        ensure   => present,
        require  => Yumrepo[ 'kermit-custom', 'kermit-thirdpart' ],
    }

    package { 'mcollective' :
        ensure   => installed,
        require  => Package[ 'mcollective-common' ],
    }

    package { 'mcollective-client' :
        ensure  => $::fqdn ? {
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

    file { '/etc/mcollective/client.cfg' :
        ensure  => $::fqdn ? {
            $nocnode => present,
            default  => absent,
        },
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content      => template( 'mcollective/client.cfg' ),
        require => Package[ 'mcollective-common' ],
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
        mode    => $::fqdn ? {
            $nocnode => '0644',
            default  => '0640',
        },
        source  => 'puppet:///public/mcollective/server-public.pem',
        notify => Service["mcollective"],
    }

    file { '/etc/mcollective/ssl/clients/noc-public.pem' :
        ensure  => present,
        require => [  Package[ 'mcollective-common' ],
                      File[ '/etc/mcollective/ssl/clients' ] ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///public/mcollective/noc-public.pem',
        notify => Service["mcollective"],
    }

    if $::fqdn == $nocnode {
        file { '/etc/mcollective/ssl/clients/noc-private.pem' :
            ensure  => present,
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
