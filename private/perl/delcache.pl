#!/usr/bin/perl

use CGI qw/:standard/;
use strict;

my $MERGE_ABSOLUTE_PATH = param('merge_absolute_path');
my $MERGE_SCRIPT = param('merge_script');

my $file = "$MERGE_ABSOLUTE_PATH/$MERGE_SCRIPT";
$file =~ s/\.\w+$/.conf/;

do $file;


die "Not in web mode" if (length($HTML::Merge::Ini::CACHE_PATH) < 6);

&recur($HTML::Merge::Ini::CACHE_PATH);

print <<HTML;
Content-type: text/html

<HTML>
<BODY onLoad="window.close();">
</BODY>
</HTML>
HTML

sub recur {
	my $dir = shift;
	foreach (glob("$dir/*")) {
		if (-d $_) {
			&recur($_);
			rmdir $_;
			next;
		}
		unlink $_;
	}
}
