#!/usr/bin/perl

use strict;

open(I, "../gif/space.gif") || die $!;

print "Content-type: gif/image\n\n";
binmode I;
binmode STDOUT;
my $buffer;
read(I, $buffer, 8192);
print $buffer;
