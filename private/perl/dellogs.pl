#!/usr/bin/perl

use CGI qw/:standard/;
use strict;

my $MERGE_ABSOLUTE_PATH = param('merge_absolute_path');
my $MERGE_SCRIPT = param('merge_script');

my $file = "$MERGE_ABSOLUTE_PATH/$MERGE_SCRIPT";
$file =~ s/\.\w+$/.conf/;

do $file;

my $log_dir = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH/$ENV{'REMOTE_ADDR'}";

die "Not in web mode" if (length($log_dir) < 6);

&recur($log_dir);

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

