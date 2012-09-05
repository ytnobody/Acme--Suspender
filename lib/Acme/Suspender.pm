package Acme::Suspender;
use strict;
use warnings;
use 5.008;
our $VERSION = '0.01';

use parent 'Class::Accessor::Fast';

use Carp;
use Furl;
use JSON;
use Try::Tiny;
use URI;

our @threshold = (
    'HELP!'     => sub { shift > 30 },
    'Ugggg....' => sub { shift > 10 },
    'Oops...'   => sub { shift > 0 },
    "I'm Okay." => sub { 1 },
);

__PACKAGE__->mk_accessors( qw( user repo parser agent interval endpoint ) );

sub as_array ($) {
    my $var = shift;
    return ref $var eq 'ARRAY' ? @$var : ( $var );
}

sub say ($) {
    my $var = shift;
    printf "%s\n", $var;
}

sub new {
    my ( $class, %opts ) = @_;

    $opts{interval} ||= 6000;
    $opts{endpoint} ||= 'https://api.github.com/';
    $opts{parser}   ||= 'JSON';
    $opts{agent}    ||= Furl->new(
        agent => join('/', $class, $VERSION),
        timeout => 10,
    );

    my $self = $class->SUPER::new( { %opts } );

    return $self;
}

sub get {
    my ( $self, $path ) = @_;
    my $uri = URI->new( $self->endpoint );
    $uri->path( $path );

    my $res = $self->agent->get( $uri );
    Carp::croak( sprintf "%s(code:%s)", $res->content, $res->code ) unless $res->is_success;
    return try {
        JSON->new->utf8->decode( $res->content );
    } catch {
        Carp::croak( sprintf "%s(uri:%s)", $_, $uri->as_string );
    };

}

sub get_pullreq {
    my ( $self ) = @_;

    my $pullreq = 0;
    my $res = $self->get( sprintf "/repos/%s/%s/%s", $self->user, $self->repo, 'pulls' );
    $pullreq += scalar grep { /number/ } keys %{$_} for as_array $res;

    return $pullreq;
}

sub poll {
    my ( $self ) = @_;
    while (1) {
        my $pullreq = $self->get_pullreq;

        # Following statements will replace from outputting message to outputting images.
        for my $i ( 0 .. scalar( @threshold ) / 2 ) {
            my $message = $threshold[$i * 2];
            my $code = $threshold[($i * 2) + 1];
            if ( $code->( $pullreq ) ) {
                say $message;
                last;
            }
        }
        sleep $self->interval;
    }
}

1;
__END__

=head1 NAME

Acme::Suspender -

=head1 SYNOPSIS

  use Acme::Suspender;

=head1 DESCRIPTION

Acme::Suspender is

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
