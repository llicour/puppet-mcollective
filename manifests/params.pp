# Parameters for MCollective
#
# The Marionette Collective AKA MCollective is a framework to build
# server orchestration or parallel job execution systems.

class mcollective::params (
   $amqp_server   = 'el6.labolinux.fr',
   $amqp_user     = 'noc',
   $amqp_password = 'nocpassword',
) {

}
