#!/usr/bin/perl
##################################################################
# web_ini.pl - Gets the data to update in the ini.pm             #
#              from the Merge Configuration Web page             #
# Author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2002 #
# Date : 07/05/2001                                              #
# updated :                                                      #
##################################################################

use HTML::Merge::Engine;
use HTML::Merge::Development;

use CGI qw/:standard/;
use strict qw(vars subs);

ReadConfig();

my $state = 0;
open(INPUT, $file);
my @lines;
while (<INPUT>) {
	chop;
	if (!$state) {
		$state++ if /^package/;
	} elsif ($state == 1) {
		$state++ if /^#/;
	} else {
		next if /^#/;
		@lines = ($_);
		last;
	}
}

while (<INPUT>) {
        chop;
	last if (/^return /);
	eval {
		require Text::Tabs;
		($_) = Text::Tabs::expand($_);
	};
	push(@lines, $_);
}

close(INPUT);

my @vars = param();
my %hash;
@hash{@vars} = @vars;
my $code;
my $db_pass = HTML::Merge::Engine::Convert(param('DB_PASSWORD'), 1);

foreach my $v (@vars) {
	my $item =join(",", grep /./, param($v));
	$item =~ s/'/\\'/g;
	if ($v eq 'SUPPORT_SITE') {
		eval '
			use URI::Heuristic qw(uf_uristr);
			$item = uf_uristr($item);
		';
	}
	if ($v eq 'DB_PASSWORD2') {
		$item = $db_pass;
	}
	if ($v eq 'DB_PASSWORD') {
		$item = '';
	}

print STDERR "$v = $item\n";
	foreach (@lines) {
		my $extra;
		my $pos;
		if (/;\s*#/) {
			$pos = length($_) - length($') - 1;
			$extra = substr($_, $pos);
		}
			
		if (s/\$$v\s*=.*$/\$$v = '$item';/) {
			delete $hash{$v};
			if ($extra) {
				$_ = sprintf("%-${pos}s", $_) . $extra;
			}
		}
	}
}

if (%hash) {
	foreach (keys %hash) {
		my $item = join(",", grep /./, param($_));
		$item =~ s/'/\\'/g;
		push(@lines, "\$$_ = '$item';");
	}
}

unless (open(OUTPUT, ">$file")) {
	print "Status: 403 Permission denied\n";
	print "Content-type: text/plain\n\n";
	print "Could not rewrite $file: $!";
	exit;
}

HTML::Merge::Development::WriteConfig(\*OUTPUT);

print OUTPUT join("\n", @lines, "");

close OUTPUT;

&ReadConfig; # Need to read $file and calculate $extra

print "Location: pre_web_ini.pl?$extra\n\n";
