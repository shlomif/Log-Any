use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::File;

# ABSTRACT: Simple adapter for logging to files
our $VERSION = '0.92'; # TRIAL

use IO::File;
use Log::Any::Adapter::Util ();

use base qw/Log::Any::Adapter::Base/;

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');
sub new {
    my ( $class, $file, @args ) = @_;
    return $class->SUPER::new( file => $file, log_level => $trace_level, @args );
}

sub init {
    my $self = shift;
    if ( exists $self->{log_level} ) {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level( $self->{log_level} )
            unless $self->{log_level} =~ /^\d+$/;
    }
    else {
        $self->{log_level} = $trace_level;
    }
    my $file = $self->{file};
    open( $self->{fh}, ">>", $file )
      or die "cannot open '$file' for append: $!";
    $self->{fh}->autoflush(1);
}

foreach my $method ( Log::Any->logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level( $method );
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        my $msg = sprintf( "[%s] %s\n", scalar(localtime), $text );
        $self->{fh}->print($msg);
      }
}

foreach my $method ( Log::Any->detection_methods() ) {
    no strict 'refs';
    my $base = substr($method,3);
    my $method_level = Log::Any::Adapter::Util::numeric_level( $base );
    *{$method} = sub {
        return !!(  $method_level <= $_[0]->{log_level} );
    };
}

1;

__END__

=head1 SYNOPSIS

    use Log::Any::Adapter ('File', '/path/to/file.log');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('File', '/path/to/file.log');

    # with minimum level 'warn'

    use Log::Any::Adapter (
        'File', '/path/to/file.log', log_level => 'warn',
    );

=head1 DESCRIPTION

This simple built-in L<Log::Any|Log::Any> adapter logs each message to the
specified file, with a datestamp prefix and newline appended. The file is
opened for append with autoflush on. Category is ignored.

The C<log_level> attribute may be set to define a minimum level to log.

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

