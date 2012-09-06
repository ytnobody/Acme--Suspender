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
use File::Spec;
use File::Basename;

our @threshold = (
    'too_much,jpg' => sub { shift > 30 },
    'several.jpg'  => sub { shift > 10 },
    'few.jpg'      => sub { shift > 0 },
    "nothing.jpg"  => sub { 1 },
);

__PACKAGE__->mk_accessors( qw( user repo parser agent endpoint ) );

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

sub display_image {
    my ( $self, $img_file_location ) = @_;

    open( my $img, $img_file_location ) or die "Error: $!";
    binmode $img;
    binmode STDOUT;
    print "Content-type: image/jpeg\n\n";
    print while (<$img>);
    close($img);
}

sub main {
    my ( $self ) = @_;

    my $way_to_this_module = dirname( File::Spec->rel2abs( __FILE__ ) );
    my $pullreq = $self->get_pullreq;
    for my $i ( 0 .. scalar( @threshold ) / 2 ) {
        my $filename = $threshold[$i * 2];
        my $code = $threshold[($i * 2) + 1];
        if ( $code->( $pullreq ) ) {
            $self->display_image("$way_to_this_module/Suspender/$filename");
            last;
        }
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
