#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib");

use Acme::Suspender;

my $dan = Acme::Suspender->new( user => 'plack', repo => 'Plack' );

$dan->poll;
