#!/usr/bin/perl

use HTML::Merge::Development;
use CGI qw/:standard/;
use strict;

#&ReadConfig;

my $sub = param("sub");
my $fun = "Default$sub";

print header;

print "This script is obsolete\n";
exit;

my $code = UNIVERSAL::can('HTML::Merge::Development', $fun);

if ($code) {
	&$code;
	exit;
}

DefaultError("Improper use of Merge internal");
