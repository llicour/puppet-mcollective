# Install and configure MCollective client (management node)
# Set MCollective with the OpenSSL based Security Plugin
#
# The Marionette Collective AKA MCollective is a framework to build
# server orchestration or parallel job execution systems.

class mcollective::client ( $key = 'noc' ) {

    include mcollective::params

    include yum
    include kermit::yum

    package { 'mcollective-common' :
        ensure   => present,
        require  => Yumrepo[ 'kermit-custom', 'kermit-thirdpart' ],
    }

    package { 'mcollective-client' :
        ensure   => present,
        require => Package[ 'mcollective-common' ],
    }

    file { '/etc/mcollective/sslclient' :
        ensure  => 'directory',
        require => Package[ 'mcollective-common' ],
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/etc/mcollective/client.cfg' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content      => template( 'mcollective/client.cfg' ),
        require => Package[ 'mcollective-common', 'mcollective-client' ],
    }

    file { '/etc/mcollective/sslclient/server-public.pem' :
        ensure  => present,
        require => [  Package[ 'mcollective-common' ],
                      File[ '/etc/mcollective/sslclient' ] ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',  # 644 for passenger
        source  => 'puppet:///public/mcollective/server-public.pem',
    }

    file { "/etc/mcollective/sslclient/$key-public.pem" :
        ensure  => present,
        require => [  Package[ 'mcollective-common' ],
                      File[ '/etc/mcollective/sslclient' ] ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///public/mcollective/clients/$key-public.pem",
    }

    file { "/etc/mcollective/sslclient/$key-private.pem" :
        ensure  => present,
        require => [  Package[ 'mcollective-common' ],
                      File[ '/etc/mcollective/sslclient' ] ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///private/mcollective/$key-private.pem",
    }

}
