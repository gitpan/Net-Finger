##################################################################
#                                                                #
#  Net::Finger, a Perl implementation of a finger client.        #
#                                                                #
#  By Dennis "FIMM" Taylor, <corbeau@execpc.com>                 #
#                                                                #
#  This module may be used and distributed under the same terms  #
#  as Perl itself. See your Perl distribution for details.       #
#                                                                #
##################################################################


package Net::Finger;

use strict;
use Socket;
use Carp;
use vars qw($VERSION @ISA @EXPORT $error);
use constant DEBUG => 0;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( &finger );

$VERSION = '1.01';



# I know the if (DEBUG) crap gets in the way of the code a bit, but it's
# a worthy sacrifice from a debugging perspective. Bear in mind that
# Perl's internal compiler will discard the stuff in the DEBUG blocks at
# compile-time. Nifty.


sub finger {
    my ($addr, $verbose) = @_;
    my ($host, $request, @lines);

    unless (@_) {
        carp "Not enough arguments to Net::Finger::finger()";
    }

    # Set the error indicator to something innocuous.
    $error = "";

    $addr ||= '';
    if (index( $addr, '@' ) >= 0) {
        my @tokens = split /\@/, $addr;
        $host = pop @tokens;
        $request = join '@', @tokens;
        
    } else {
        $host = 'localhost';
        $request = $addr;
    }

    if ($request and $verbose) {
        $request = "/W $request";
    }

    if (DEBUG) {
        warn "Creating a new socket.\n";
    }

    unless (socket( SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
        $error = "Can\'t create a new socket: $!";
        return;
    }
    select SOCK;  $| = 1;  select STDOUT;

    if (DEBUG) {
        warn "Connecting to $host, port ",
            (getservbyname('finger', 'tcp'))[2], ".\n";
    }

    unless (connect( SOCK,
                     sockaddr_in((getservbyname('finger', 'tcp'))[2],
                                 inet_aton($host)) ))
    {
        $error = "Can\'t connect to $host: $!";
        return;
    }

    if (DEBUG) {
        warn "Sending request: \"$request\"\n";
    }

    print SOCK "$request\015\012";

    if (DEBUG) {
        warn "Waiting for response.\n";
    }

    while (<SOCK>) {
        push @lines, $_;
    }

    if (DEBUG) {
        warn "Response received. Closing connection.\n";
    }

    close SOCK;
    return( wantarray ? @lines : join('', @lines) );
}



1;
__END__

=head1 NAME

Net::Finger - a Perl implementation of a finger client.

=head1 SYNOPSIS

  use Net::Finger;

  # You can put the response in a scalar...
  $response = finger('corbeau@execpc.com');
  unless ($response) {
      warn "Finger problem: $Net::Finger::error";
  }

  # ...or an array.
  @lines = finger('corbeau@execpc.com', 1);

=head1 DESCRIPTION

Net::Finger is a simple, straightforward implementation of a finger client
in Perl -- so simple, in fact, that writing this documentation is almost
unnecessary.

This module has one automatically exported function, appropriately
entitled C<finger()>. It takes two arguments:

=over

=item *

A username or email address to finger. (Yes, it does support the
vaguely deprecated "user@host@host" syntax.)

=item *

(Optional) A boolean value for verbosity. True == verbose output. If
you don't give it a value, it defaults to false.

=back

C<finger()> is context-sensitive. If it's used in a scalar context, it
will return the server's response in one large string. If it's used in
an array context, it will return the response as a list, line by
line. If an error of some sort occurs, it returns undef and puts a
string describing the error into the package global variable
C<$Net::Finger::error>.

Here's a sample program that implements a very tiny, stripped-down
finger(1):

    #!/usr/bin/perl -w

    use Net::Finger;
    use Getopt::Std;
    use vars qw($opt_l);

    getopts('l');
    $x = finger($ARGV[0], $opt_l);

    if ($x) {
        print $x;
    } else {
        warn "$0: error: $Net::Finger::error\n";
    }

=head1 BUGS

=over

=item *

Doesn't yet do non-blocking requests. (FITNR. Really.)

=item *

Doesn't do local requests unless there's a finger server running on localhost.

=item *

Contrary to the name's implications, this module involves no teledildonics.

=head1 AUTHOR

Dennis Taylor, E<lt>corbeau@execpc.comE<gt>

=head1 SEE ALSO

perl(1), finger(1), RFC 1288.

=cut
